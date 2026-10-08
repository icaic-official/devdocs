module Docs
  class Nltk
    class CleanHtmlFilter < Filter
      def call
        # [source] links to the _modules pages, which aren't scraped
        css('.viewcode-link').each { |node| (node.ancestors('a').first || node).remove }

        # "name : type" terms (the theme adds the colon with CSS)
        css('dt > .classifier').each { |node| node.before(' : ') }

        doc
      end
    end
  end
end
