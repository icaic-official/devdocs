module Docs
  class Seaborn
    class CleanHtmlFilter < Filter
      def call
        # "name : type" terms (the theme adds the colon with CSS)
        css('dt > .classifier').each { |node| node.before(' : ') }
        css('img[srcset]').remove_attribute('srcset')
        doc
      end
    end
  end
end
