module Docs
  class Pydantic
    class CleanHtmlFilter < Filter
      def call
        title = at_css('h1#_top')
        content = at_css('.sl-markdown-content')
        doc.inner_html = "<h1>#{CGI.escapeHTML(title.content.strip)}</h1>"
        doc << content.children

        css('svg', 'script', 'style', '.sl-anchor-link', '.feedback-widget').remove

        # "<div class="sl-heading-wrapper level-h2"><h2 id="…">"; parameter
        # headings are paragraphs
        css('.sl-heading-wrapper').each do |node|
          heading = node.element_children.first
          node.replace(heading)
        end

        # tabs (e.g. "Python 3.9 and above" / "Python 3.10 and above") are
        # shown one after the other, each under its label
        css('starlight-tabs').each do |node|
          labels = node.css('[role="tab"]').map { |tab| [tab['href'].to_s.delete_prefix('#'), tab.content.strip] }.to_h
          panels = node.css('[role="tabpanel"]').map do |panel|
            "<p class=\"_pydantic-tab\"><strong>#{CGI.escapeHTML(labels[panel['id']].to_s)}</strong></p>#{panel.inner_html}"
          end
          node.replace(panels.join)
        end

        # annotated code: the "# (1)" annotations are popovers on the site
        css('.annotated-code').each do |node|
          notes = node.css('.annotation-popover-content').map { |note| "<li>#{note.inner_html}</li>" }
          figure = node.at_css('pre')
          node.replace(notes.empty? ? figure : "#{figure.to_html}<ol class=\"_pydantic-annotations\">#{notes.join}</ol>")
        end

        css('pre').each do |node|
          code = node.at_css('code')
          lang = code && code['class'].to_s[/language-(\w+)/, 1]
          node.content = node.content.chomp
          node.attributes.each_key { |attr| node.remove_attribute(attr) }
          node['data-language'] = lang.nil? || lang == 'py' ? 'python' : lang
          node['data-language'] = 'bash' if %w(sh shell console).include?(node['data-language'])
        end
        css('figure').each { |node| node.before(node.children).remove }

        # "API Documentation" disclosures
        css('details').each { |node| node['open'] = 'open' }

        css('[class*="astro-"]').each do |node|
          node['class'] = node['class'].split.reject { |c| c.start_with?('astro-') }.join(' ')
          node.remove_attribute('class') if node['class'].empty?
        end
        css('[dir]').remove_attribute('dir')

        # status badges
        css('img[src*="shields.io"]', 'img[src*="pepy.tech"]', 'img[src*="badge"]').each do |node|
          (node.parent.name == 'a' ? node.parent : node).remove
        end

        doc
      end
    end
  end
end
