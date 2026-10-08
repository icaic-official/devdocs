module Docs
  class SentenceTransformers
    class CleanHtmlFilter < Filter
      def call
        css('.rst-footer-buttons', '.tab-input', 'br').remove
        # [source] links to the _modules pages, which aren't scraped
        css('.viewcode-link').each { |node| (node.ancestors('a').first || node).remove }

        # sphinx-tabs: the panes are all in the page, shown one at a time with CSS
        css('.tab-label').each do |node|
          node.name = 'p'
          node['class'] = 'hf-tab'
          node.remove_attribute('for')
        end
        css('.tab-set', '.tab-content').each do |node|
          node.before(node.children).remove
        end

        # the link cards at the top of some guides
        css('.components').each do |node|
          items = node.css('a.box').map do |box|
            header = box.at_css('.header')
            title = header ? header.content.strip : ''
            header&.remove
            %(<li><a href="#{box['href']}">#{CGI.escapeHTML(title)}</a>: #{CGI.escapeHTML(box.content.strip)}</li>)
          end
          node.replace("<ul>#{items.join}</ul>")
        end

        css('pre.mermaid').each do |node|
          node.content = node.content.strip
          node.remove_attribute('class')
        end

        css('.sidebar').each do |node|
          node.name = 'div'
          node['class'] = 'admonition note'
          title = node.at_css('.sidebar-title')
          title['class'] = 'admonition-title' if title
        end

        doc
      end
    end
  end
end
