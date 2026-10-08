module Docs
  class Lightgbm
    class CleanHtmlFilter < Filter
      def call
        # [source] links to the _modules pages, which aren't scraped
        css('.viewcode-link').each { |node| (node.ancestors('a').first || node).remove }

        # "name : type" terms (the theme adds the colon with CSS)
        css('dt > .classifier').each { |node| node.before(' : ') }

        # The parameters' anchors are links with a link emoji after their name:
        # the id goes to the list item, the emoji goes away
        css('.raw-html > a[id]').each do |node|
          item = node.ancestors('li').first
          item['id'] = node['id'] if item && !item['id']
          space = node.parent.previous
          space.content = space.content.rstrip if space&.text?
          node.parent.remove
        end

        doc
      end
    end
  end
end
