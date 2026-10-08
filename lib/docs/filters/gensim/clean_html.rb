module Docs
  class Gensim
    class CleanHtmlFilter < Filter
      def call
        # [source] links to the _modules pages, which aren't scraped
        css('.viewcode-link').each { |node| (node.ancestors('a').first || node).remove }

        # "name : type" terms (the theme adds the colon with CSS)
        css('dt > .classifier').each { |node| node.before(' : ') }

        # sphinx-gallery: download links, timings and thumbnails
        css('.sphx-glr-footer', '.sphx-glr-download', '.sphx-glr-download-link-note', '.sphx-glr-signature',
            '.sphx-glr-timing').remove
        css('.sphx-glr-thumbcontainer').each do |node|
          link = node.at_css('a.reference')
          link ? node.replace("<p>#{link.to_html}</p>") : node.remove
        end
        css('.sphx-glr-thumbnails', '.sphx-glr-clear').each { |node| node.before(node.children).remove }
        css('img[srcset]').remove_attribute('srcset')

        # "highlight-Python" (sphinx-gallery) -> "highlight-python"
        css('div[class*="highlight-"]').each do |node|
          node['class'] = node['class'].sub(/highlight-([\w+]+)/) { "highlight-#{$1.downcase}" }
        end

        doc
      end
    end
  end
end
