module Docs
  class Pyarrow
    class CleanHtmlFilter < Filter
      def call
        @doc = at_css('.bd-article')

        css('.headerlink', '.viewcode-link').remove

        # sphinx/clean_html flattens parameter names and types into one <code>
        css('dt > .classifier').each { |node| node.before(' : ') }

        css('.pst-scrollable-table-container').each { |node| node.before(node.children).remove }

        doc
      end
    end
  end
end
