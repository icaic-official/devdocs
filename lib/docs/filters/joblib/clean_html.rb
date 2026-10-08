module Docs
  class Joblib
    class CleanHtmlFilter < Filter
      def call
        # "name : type" terms (the theme adds the colon with CSS)
        css('dt > .classifier').each { |node| node.before(' : ') }

        # sphinx-gallery: the example thumbnails (in the gallery index and
        # under "Examples using ...") become plain lists of links
        css('.sphx-glr-thumbnails').each do |node|
          links = node.css('.sphx-glr-thumbcontainer').map do |container|
            link = container.at_css('a')
            "<li>#{link.to_html}</li>" if link
          end
          node.replace("<ul>#{links.compact.join}</ul>")
        end

        # download buttons and timing notes
        css('.sphx-glr-footer', '.sphx-glr-download', '.sphx-glr-download-link-note', '.sphx-glr-signature',
            '.sphx-glr-timing').remove
        css('img[srcset]').remove_attribute('srcset')

        doc
      end
    end
  end
end
