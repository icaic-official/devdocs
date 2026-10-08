module Docs
  class Pillow
    class CleanHtmlFilter < Filter
      def call
        css('.viewcode-link').each { |node| (node.ancestors('a').first || node).remove }
        css('dt > .classifier').each { |node| node.before(' : ') }
        css('img[srcset]').remove_attribute('srcset')
        doc
      end
    end
  end
end
