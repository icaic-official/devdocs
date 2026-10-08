module Docs
  class H5py
    class CleanHtmlFilter < Filter
      def call
        css('.viewcode-link').each { |node| (node.ancestors('a').first || node).remove }
        css('dt > .classifier').each { |node| node.before(' : ') }
        doc
      end
    end
  end
end
