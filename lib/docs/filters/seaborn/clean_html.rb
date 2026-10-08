module Docs
  class Seaborn
    class CleanHtmlFilter < Filter
      def call
        # "name : type" terms (the theme adds the colon with CSS)
        css('dt > .classifier').each { |node| node.before(' : ') }
        css('img[srcset]').remove_attribute('srcset')

        # the thumbnails of the example gallery (not included) on the home page
        css('a[href*="examples/"]:has(> img)').each do |node|
          (node.ancestors('.sd-col, .col, figure').first || node).remove
        end
        doc
      end
    end
  end
end
