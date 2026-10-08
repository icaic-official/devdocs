module Docs
  class PytorchLightning
    class CleanHtmlFilter < Filter
      def call
        # The grids of fixed-height cards linking to other pages become lists
        css('.display-card-container', '.tutorials-callout-container').each do |container|
          items = container.css('[class*="col-md-"]').map do |column|
            title = column.at_css('h3, h4')
            next unless title
            link = column.at_css('a[href]')
            summary = column.at_css('p.body-paragraph') || column.css('p').find { |node| !node.ancestors.include?(title) }
            text = link ? %(<a href="#{link['href']}">#{title.inner_html.strip}</a>) : "<strong>#{title.inner_html.strip}</strong>"
            text << " &mdash; #{summary.inner_html.strip}" if summary
            "<li>#{text}</li>"
          end
          container.replace("<ul>#{items.compact.join}</ul>")
        end

        css('[style*="display:none"]', '[style*="display: none"]').remove

        css('.row', '[class*="col-md-"]').each do |node|
          node.before(node.children).remove
        end

        css('[style]').remove_attribute('style')

        doc
      end
    end
  end
end
