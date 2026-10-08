module Docs
  class Huggingface
    # Cleans the pages rendered by doc-builder's Svelte components. The
    # docstrings become definition lists, as in the Sphinx docs:
    #
    #   <dl class="hf-class">
    #     <dt id="transformers.Trainer">class transformers.Trainer(model, args, ...)</dt>
    #     <dd>parameters, returns, description and the methods' docstrings</dd>
    #   </dl>
    class CleanHtmlFilter < Filter
      LANGUAGES = { 'py' => 'python', 'sh' => 'bash', 'shell' => 'bash', 'console' => 'bash', 'yml' => 'yaml',
                    'js' => 'javascript', 'ts' => 'typescript', 'jsonc' => 'json', 'py3' => 'python', 'pycon' => 'python' }

      def call
        doc.xpath('.//comment()').remove
        css('meta', 'link', 'script', 'style', 'noscript', 'svg', 'button').remove

        # model pages open with their publication dates and badges
        if (h1 = at_css('h1')) && h1 != doc.element_children.first
          doc.children.first.before(h1)
        end

        clean_math
        clean_docstrings
        clean_headings
        clean_code
        clean_embeds

        css('blockquote.tip', 'blockquote.warning').each do |node|
          node.name = 'div'
          node['class'] = node['class'] == 'warning' ? 'note note-warning' : 'note'
        end

        # GitHub alerts in the Markdown rendered by Huggingface::TabsFilter
        css('blockquote').each do |node|
          next unless (first = node.at_css('> p:first-child')) && first.inner_html =~ /\A\s*\[!(\w+)\]\s*(<br>)?/
          kind = $1.downcase
          first.inner_html = first.inner_html.sub(/\A\s*\[!\w+\]\s*(<br>)?\s*/, '')
          first.remove if first.content.strip.empty? && first.element_children.empty?
          node.name = 'div'
          node['class'] = %w(warning caution important).include?(kind) ? 'note note-warning' : 'note'
        end

        # badges of the features a model supports ("SDPA", "FlashAttention")
        css('img[src*="img.shields.io"]').each do |node|
          node.replace(%(<span class="hf-badge">#{CGI.escapeHTML(node['alt'].to_s)}</span>))
        end

        css('table').each do |node|
          node.wrap('<div class="hf-table"></div>') unless node.parent['class'] == 'hf-table'
        end

        # Tailwind's classes
        css('*').each do |node|
          next unless node['class']
          classes = node['class'].split.select { |name| name.start_with?('hf-') || %w(note note-warning).include?(name) }
          classes.empty? ? node.remove_attribute('class') : node['class'] = classes.join(' ')
        end

        # Svelte's wrappers, which carry no meaning once the classes are gone
        css('div:not([class]):not([id]), span:not([class]):not([id])').each do |node|
          node.before(node.children).remove
        end

        3.times do
          css('p, div, span, li, ul').each do |node|
            node.remove if node.content.strip.empty? && node.element_children.empty? && !node['id']
          end
        end

        css('[data-svelte-h]').remove_attribute('data-svelte-h')
        css('[style]').remove_attribute('style')
        css('a[target]').remove_attribute('target')
        css('a[rel]').remove_attribute('rel')

        doc
      end

      # KaTeX ships MathML next to its HTML rendering.
      def clean_math
        css('.katex-display').each do |node|
          math = node.at_css('math')
          next node.remove unless math
          math['display'] = 'block'
          node.replace(math)
        end

        css('.katex').each do |node|
          math = node.at_css('math')
          math ? node.replace(math) : node.remove
        end

        css('math annotation').remove
      end

      def clean_docstrings
        # innermost first, as the methods are nested in their classes
        css('div.docstring').reverse_each do |node|
          header = node.at_css('> div:first-child')
          title = header&.at_css('span[id]')
          heading = title&.at_css('h3, h4')
          next unless heading

          id = title['id']
          kind = if heading.at_css('.font-light')&.content&.strip == 'class' then 'class'
                 elsif node.ancestors('div.docstring').any? then 'method'
                 else 'function'
                 end

          signature = signature_of(header, heading)
          source = title.css('a[href]').find { |a| a['href'].start_with?('http') }

          dt = %(<dt id="#{id}">#{signature})
          dt << %(<a class="hf-source" href="#{source['href']}">[source]</a>) if source
          dt << '</dt>'

          details = header.at_css('.docstring-details')
          clean_details(details) if details
          details ? header.replace(details.children) : header.remove

          node.name = 'dl'
          node['class'] = "hf-docstring hf-#{kind}"
          node.inner_html = "#{dt}<dd>#{node.inner_html}</dd>"
        end
      end

      def signature_of(header, heading)
        name = heading.css('.font-medium, .font-semibold').map(&:content).join.strip
        name = heading.content.strip.sub(/\Aclass\s+/, '') if name.empty?
        prefix = heading.at_css('.font-light')&.content&.strip == 'class' ? '<em class="hf-prefix">class</em> ' : ''

        signature = header.at_css('> p.font-mono')
        params = signature ? signature.css('.comma').map { |param| CGI.escapeHTML(param.content.strip.squeeze(' ')) } : []
        returns = signature&.at_css('.font-bold + span')&.content&.strip

        html = +"#{prefix}<code>#{CGI.escapeHTML(name)}"
        html << "(#{params.join(', ')})" if signature
        html << " → #{CGI.escapeHTML(returns)}" if returns.present?
        html << '</code>'
      end

      def clean_details(details)
        # "Parameters", "Attributes", ... and their lists
        details.css('> p.font-semibold').each do |label|
          label.inner_html = "<strong>#{CGI.escapeHTML(label.content.strip)}</strong>"
          label['class'] = 'hf-label'
        end

        details.css('ul > li').each do |item|
          anchor = item.at_css('a.header-link[id]')
          next unless anchor
          item['id'] = anchor['id']
          anchor.remove
        end

        # "Returns" / "Raises": a label, the type, and the description after it
        details.css('div[id$=".returns"], div[id$=".raises"], div[id$=".yields"]').each do |block|
          label = block.at_css('p.text-base')
          title = label ? label.content.strip : 'Returns'
          label&.remove
          block.css('span.flex-auto').remove
          block.children.first.before(%(<p class="hf-label"><strong>#{CGI.escapeHTML(title)}</strong></p>)) if block.children.first
          block['class'] = 'hf-returns'
        end
      end

      def clean_headings
        css('h1, h2, h3, h4, h5, h6').each do |node|
          anchor = node.at_css('a.header-link[id]')
          next unless anchor
          node['id'] ||= anchor['id']
          anchor.remove
          node.inner_html = node.inner_html.strip
        end

        css('a.header-link').each do |node|
          node.parent['id'] ||= node['id'] if node['id']
          node.remove
        end
      end

      def clean_code
        css('.code-block').each do |node|
          pre = node.at_css('pre')
          next node.remove unless pre
          node.replace(code_block(pre, pre['class'].to_s[/language-(\S+)/, 1]))
        end

        css('pre').each do |pre|
          next if pre['data-language'] || pre['class'] == 'hf-code'
          code = pre.at_css('> code')
          language = (code || pre)['class'].to_s[/language-(\S+)/, 1]
          pre.replace(code_block(pre, language))
        end
      end

      def code_block(pre, language)
        language = LANGUAGES.fetch(language.to_s, language.to_s)
        new_pre = doc.document.create_element('pre')
        new_pre.content = pre.content.sub(/\A\n+/, '').rstrip
        new_pre['data-language'] = language if language.present? && language != 'text'
        new_pre
      end

      def clean_embeds
        css('iframe[src]').each do |node|
          src = node['src']
          src = "https:#{src}" if src.start_with?('//')
          label = src.include?('youtube') ? 'YouTube video' : 'Embedded content'
          node.replace(%(<p><a href="#{src}">#{label}: #{CGI.escapeHTML(src)}</a></p>))
        end

        css('video').each do |node|
          src = node['src'] || node.at_css('source[src]')&.[]('src')
          node.replace(src ? %(<p><a href="#{src}">Video: #{CGI.escapeHTML(src)}</a></p>) : '')
        end
      end
    end
  end
end
