require 'execjs'

module Docs
  class Spacy
    # spacy.io renders its code blocks in the browser: the server-rendered
    # pages contain empty <pre> elements. This fills them with the code of the
    # page's compiled MDX (in __NEXT_DATA__), which it evaluates with a JSX
    # runtime that collects the fenced code blocks in document order. The
    # "101" sections the usage guides share are separate MDX files, whose code
    # blocks come from the sources of the release.
    #
    # It also records the page's section in the sidebar for the entries filter.
    class CodeFilter < Filter
      PARTIALS_URL = 'https://raw.githubusercontent.com/explosion/spaCy/release-v3.8.16/website/docs/usage/101/'
      PARTIALS = {
        'Architecture101' => '_architecture', 'LanguageData101' => '_language-data', 'NER101' => '_named-entities',
        'Pipelines101' => '_pipelines', 'PosDeps101' => '_pos-deps', 'Serialization101' => '_serialization',
        'Tokenization101' => '_tokenization', 'Training101' => '_training', 'Vectors101' => '_vectors-similarity'
      }

      LANGUAGES = {
        'python' => 'python', 'py' => 'python', 'bash' => 'bash', 'cli' => 'bash', 'shell' => 'bash',
        'json' => 'json', 'yaml' => 'yaml', 'yml' => 'yaml', 'diff' => 'diff', 'javascript' => 'javascript',
        'js' => 'javascript', 'jsx' => 'jsx', 'markdown' => 'markdown', 'html' => 'markup', 'cython' => 'python'
      }

      CODE_BLOCKS = <<~JS
        function codeBlocks(src) {
          var blocks = [], components = {}, m;
          var re = /_jsxs?\\(([A-Za-z_$][\\w$]*)[,)]/g;
          while ((m = re.exec(src))) components[m[1]] = m[1];
          var destructured = /\\{([^{}]*)\\} = _components/g;
          while ((m = destructured.exec(src))) {
            m[1].split(',').forEach(function(name) {
              name = name.split(':')[0].trim();
              if (name) components[name] = name;
            });
          }
          function jsx(type, props) {
            props = props || {};
            if (type === 'code' && (props.lang !== undefined || /language-/.test(props.className || ''))) {
              var code = props.children;
              if (Array.isArray(code)) code = code.join('');
              blocks.push({ lang: props.lang || (props.className || '').replace(/^language-/, ''),
                            code: code == null ? '' : String(code) });
            } else if (typeof type === 'string' && /101$/.test(type)) {
              blocks.push({ partial: type });
            }
            return null;
          }
          var runtime = { Fragment: 'Fragment', jsx: jsx, jsxs: jsx, jsxDEV: jsx,
                          useMDXComponents: function() { return components; } };
          new Function(src)(runtime).default({});
          return blocks;
        }
      JS

      def self.context
        @context ||= ExecJS.compile(CODE_BLOCKS)
      end

      def self.partial_blocks(name)
        @partials ||= {}
        @partials[name] ||= begin
          url = "#{PARTIALS_URL}#{PARTIALS.fetch(name)}.mdx"
          response = Request.run(url)
          raise "Failed to fetch #{url} (#{response.code})" unless response.success?
          fenced_blocks(response.body)
        end
      end

      # The fenced code blocks, also in quotes ("> ```python"), which the
      # site shows beside the text
      def self.fenced_blocks(mdx)
        blocks = []
        prefix = nil
        mdx.each_line do |line|
          if prefix.nil?
            next unless match = line.match(/\A(\s*(?:>\s?)?)```(\w*)/)
            prefix = match[1]
            blocks << { 'lang' => match[2], 'code' => +'' }
          elsif line.start_with?("#{prefix}```") || line.rstrip == "#{prefix.rstrip}```"
            prefix = nil
          else
            blocks.last['code'] << (line.start_with?(prefix) ? line.delete_prefix(prefix) : line.delete_prefix(prefix.rstrip))
          end
        end
        blocks
      end

      def call
        script = at_css('script#__NEXT_DATA__')
        source = script && JSON.parse(script.content).dig('props', 'pageProps', 'mdx', 'compiledSource')
        return doc unless source

        # the sidebar's section of the page, for the entries filter
        link = at_css('a[class*="sidebar_is-active"]')
        label = link && link.ancestors('ul').first&.at_css('li[class*="sidebar_label"]')
        result[:spacy_section] = label.content.strip if label

        blocks = self.class.context.call('codeBlocks', source).flat_map do |block|
          block['partial'] ? self.class.partial_blocks(block['partial']) : [block]
        end

        pres = css('main article pre[class*="code_pre"]')
        if pres.length != blocks.length
          raise "#{current_url}: #{pres.length} code blocks in the page, #{blocks.length} in its MDX"
        end

        pres.zip(blocks).each do |pre, block|
          node = Nokogiri::XML::Node.new('pre', doc.document)
          node.content = block['code'].chomp
          lang = LANGUAGES[block['lang'].to_s.downcase]
          node['data-language'] = lang if lang
          # the code's file name, or the link to the file on GitHub
          if title = pre.at_css('[class*="code_title"], header')
            pre.before(%(<p class="_spacy-code-title">#{title.inner_html.strip}</p>))
          end
          pre.replace(node)
        end

        doc
      end
    end
  end
end
