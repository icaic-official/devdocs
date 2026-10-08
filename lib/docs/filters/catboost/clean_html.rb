module Docs
  class Catboost
    class CleanHtmlFilter < Filter
      def call
        root_page? ? clean_root : clean_page
        doc
      end

      # The landing page's cards become lists of links
      def clean_root
        title = at_css('.dc-doc-leading-page__title, h1')&.content&.strip || 'CatBoost'
        description = at_css('.dc-doc-leading-page__description')&.inner_html
        sections = css('.dc-doc-leading-page__links-item_root').map do |item|
          heading = item.at_css('.dc-doc-leading-page__links-title_root')&.content&.strip
          links = item.css('.dc-doc-leading-page__links-item:not(.dc-doc-leading-page__links-item_root)').map do |link_item|
            link = link_item.at_css('a')
            next unless link
            text = link_item.at_css('.dc-doc-leading-page__links-title')&.content&.strip || link.content.strip
            %(<li><a href="#{link['href']}">#{CGI.escapeHTML(text)}</a></li>)
          end
          "<h2>#{CGI.escapeHTML(heading.to_s)}</h2><ul>#{links.compact.join}</ul>"
        end
        doc.inner_html = "<h1>#{CGI.escapeHTML(title)}</h1><div>#{description}</div>#{sections.join}"
      end

      def clean_page
        # page chrome: contributors, the page's table of contents, feedback form
        css('.dc-doc-page__under-title-info', '.dc-doc-page__content-mini-toc', '.dc-doc-page__feedback',
            '.yfm-anchor', '.yfm-code-floating', 'button', 'svg').remove

        css('.dc-doc-page-title').each do |node|
          node.inner_html = node.content.strip
          node.remove_attribute('class')
        end
        css('.dc-doc-page__body').each { |node| node.before(node.children).remove }

        xpath('.//comment()').remove

        # Code blocks: highlight.js markup becomes plain text with a language
        css('.yfm-code-floating-container').each do |node|
          pre = node.at_css('pre')
          next node.remove unless pre
          code = pre.at_css('code')
          language = code && code['class'].to_s.split.find { |name| name != 'hljs' }
          pre.content = pre.content
          pre['data-language'] = normalize_language(language) if language
          node.replace(pre)
        end
        css('pre > code').each { |node| node.before(node.children).remove }

        # notes: "Note", "Alert", "Warning"
        css('.yfm-note').each do |node|
          title = node.at_css('.yfm-note-title')
          if title
            title.name = 'strong'
            title.remove_attribute('class')
          end
          content = node.at_css('.yfm-note-content')
          content&.before(content.children)&.remove
          node.name = 'div'
          node['class'] = node['class'].include?('yfm-accent-info') ? '_note' : '_note _note-red'
          node.remove_attribute('note-type')
        end

        # Collapsed sections ("cuts") are expanded: their title becomes a
        # heading (the innermost first, as they can be nested)
        css('details.yfm-cut').reverse_each do |node|
          summary = node.at_css('> summary')
          content = node.at_css('> .yfm-cut-content')
          title = summary ? "<h4>#{summary.inner_html}</h4>" : ''
          node.replace("#{title}<div>#{content&.inner_html}</div>")
        end

        # Tabs: every pane is shown, under its tab's name
        css('.yfm-tabs').reverse_each do |node|
          titles = node.css('.yfm-tab').map { |tab| tab.content.strip }
          panels = node.css('.yfm-tab-panel').each_with_index.map do |panel, index|
            "<h4>#{CGI.escapeHTML(titles[index].to_s)}</h4>#{panel.inner_html}"
          end
          node.replace(panels.join)
        end

        render_math

        # YouTube players (whose src the site resolves wrongly) become links
        css('iframe.youtube-player').each do |node|
          id = node['src'].to_s.split('/').last
          link = %(<p><a href="https://www.youtube.com/watch?v=#{id}">Watch the video on YouTube</a></p>)
          (node.ancestors('.embed-responsive').first || node).replace(link)
        end

        css('code').each do |node|
          node.remove_attribute('class')
          node.remove_attribute('role')
          node.remove_attribute('tabindex')
          node.remove_attribute('id') if node['id'].to_s.start_with?('inline-code-id-')
        end

        css('table').each { |node| node.remove_attribute('class') }
        css('img').each { |node| node.remove_attribute('loading') }
      end

      LANGUAGES = { 'sh' => 'bash', 'shell' => 'bash', 'console' => 'bash', 'py' => 'python', 'plaintext' => 'text' }

      def normalize_language(language)
        LANGUAGES.fetch(language, language)
      end

      # The TeX is rendered with KaTeX by the site's JavaScript: render it to
      # MathML instead, like the Sphinx math filter
      def render_math
        nodes = css('.yfm-latex[data-content]')
        return if nodes.empty?
        items = nodes.map do |node|
          tex = CGI.unescape(node['data-content'].gsub('+', '%2B'))
          options = JSON.parse(CGI.unescape(node['data-options'].to_s)) rescue {}
          [tex, options['displayMode'] == true]
        end
        Docs::Sphinx::MathFilter.context.call('renderAll', items).each_with_index do |mathml, index|
          node = nodes[index]
          node.inner_html = mathml.delete_prefix('<span class="katex">').delete_suffix('</span>')
          node['class'] = 'math'
          node.remove_attribute('data-content')
          node.remove_attribute('data-options')
        end
      end
    end
  end
end
