module Docs
  class Gymnasium
    class CleanHtmlFilter < Filter
      def call
        # "[source]" links point to the source code pages, which aren't scraped
        css('.viewcode-link').each { |node| (node.ancestors('a').first || node).remove }
        css('dt > .classifier').each { |node| node.before(' : ') }

        # sphinx-gallery: download buttons and timing notes
        css('.sphx-glr-footer', '.sphx-glr-download', '.sphx-glr-download-link-note', '.sphx-glr-signature',
            '.sphx-glr-timing').remove

        # the environments' "edit this page" links and feedback widgets
        css('.edit-this-page', '.view-this-page', '.giscus', '#giscus').remove

        css('img[srcset]').remove_attribute('srcset')
        doc
      end
    end
  end
end
