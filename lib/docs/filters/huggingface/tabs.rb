require 'cgi'

module Docs
  class Huggingface
    # doc-builder renders the first option of the tabbed blocks of a page
    #
    #   <hfoptions id="usage">
    #   <hfoption id="Pipeline"> ... </hfoption>
    #   <hfoption id="AutoModel"> ... </hfoption>
    #   </hfoptions>
    #
    # and leaves the others for the browser. This lays out every option one
    # after the other under its name: the first one as rendered, the others
    # rendered from the Markdown source of the page, whose blocks are matched to
    # the rendered ones by their option names.
    class TabsFilter < Filter
      include Instrumentable

      OPTIONS = /<hfoptions\b[^>]*>(.*?)<\/hfoptions>/m
      OPTION = /<hfoption\s+id="([^"]*)"\s*>(.*?)<\/hfoption>/m

      MARKDOWN_OPTIONS = {
        input: 'GFM',
        auto_ids: false,
        hard_wrap: false,
        syntax_highlighter: nil,
        smart_quotes: %w(apos apos quot quot),
        typographic_symbols: { hellip: '...', mdash: '---', ndash: '--', laquo: '<<', raquo: '>>',
                               laquo_space: '<< ', raquo_space: ' >>' }
      }

      LANGUAGES = { 'py' => 'python', 'sh' => 'bash', 'shell' => 'bash', 'console' => 'bash', 'yml' => 'yaml' }

      def call
        groups = css('.language-select')
        return doc if groups.empty?

        sources = source_groups
        groups.each do |group|
          tabs = group.previous_element
          labels = tabs ? tabs.element_children.map { |node| node.content.strip } : []
          index = sources.index { |source| source.map(&:first) == labels }

          if index.nil? && labels.length > 1
            instrument 'warn.doc', msg: "#{slug}: no source for the options #{labels.join(', ')}"
          end

          source = index ? sources.delete_at(index) : []
          html = +''
          labels.each_with_index do |label, i|
            html << %(<p class="hf-tab">#{CGI.escapeHTML(label)}</p>)
            html << (i.zero? ? group.inner_html : render(source.dig(i, 1).to_s))
          end

          tabs&.remove
          group.replace(%(<div class="hf-tabs">#{html.presence || group.inner_html}</div>))
        end

        doc
      end

      private

      # [[[name, markdown], ...], ...], the options of each block of the source
      def source_groups
        file = %w(.md .mdx).map { |ext| File.join(context[:mdx_directory].to_s, "#{slug}#{ext}") }.find { |f| File.exist?(f) }
        return [] unless file
        File.read(file).scan(OPTIONS).map { |(body)| body.scan(OPTION) }
      end

      def render(markdown)
        markdown = dedent(markdown)
        markdown = markdown.gsub(/<Tip\s+warning=\{true\}\s*>/, %(<blockquote class="warning" markdown="1">\n))
                           .gsub(/<Tip\s*>/, %(<blockquote class="tip" markdown="1">\n))
                           .gsub(%r{</Tip>}, "\n</blockquote>")
                           .gsub(/<Youtube\s+id="([^"]+)"\s*\/>/) { %(<a href="https://www.youtube.com/watch?v=#{$1}">YouTube video</a>) }
        markdown = transform_outside_code(markdown) { |line| link_objects(line) }
        Kramdown::Document.new(markdown, MARKDOWN_OPTIONS.deep_dup).to_html
      end

      def dedent(text)
        indent = text.lines.reject { |line| line.strip.empty? }.map { |line| line[/\A */].length }.min.to_i
        text.lines.map { |line| line.sub(/\A {0,#{indent}}/, '') }.join
      end

      # Yields the lines that aren't inside fenced code blocks, and normalizes
      # the languages of the fences.
      def transform_outside_code(text)
        fence = nil
        text.lines.map do |line|
          if fence
            fence = nil if line.match?(/\A\s*#{Regexp.escape(fence)}\s*\z/)
            line
          elsif (match = line.match(/\A(\s*)(```+|~~~+)\s*(\w*)[^\n]*\n?\z/))
            fence = match[2]
            "#{match[1]}#{match[2]}#{LANGUAGES.fetch(match[3], match[3])}\n"
          else
            yield line
          end
        end.join
      end

      # doc-builder's links to the API: [`Trainer`], [`~Trainer.train`]
      def link_objects(line)
        line.gsub(/\[`(~?)([\w.]+)(\(\))?`\](?![(\[])/) do
          short, name, call = $1, $2, $3
          label = CGI.escapeHTML("#{short.empty? ? name : name.split('.').last}#{call}")
          anchor = [name, "#{context[:package]}.#{name}"].find { |id| context[:anchors]&.key?(id) }
          if anchor
            %(<a href="#{base_url}#{context[:anchors][anchor]}##{anchor}"><code>#{label}</code></a>)
          else
            "<code>#{label}</code>"
          end
        end
      end
    end
  end
end
