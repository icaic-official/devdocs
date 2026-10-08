module Docs
  class Tensorboard
    class EntriesFilter < Docs::EntriesFilter
      def get_name
        at_css('h1').content.strip
      end

      def get_type
        'Guides'
      end

      # The sections of the README: usage, key concepts, dashboards and FAQ
      def additional_entries
        return [] unless root_page?

        css('h1[id]', 'h3[id]').each_with_object([]) do |node, entries|
          next if node.name == 'h1' && node == at_css('h1')
          entries << [node.content.strip, node['id'], 'README']
        end
      end
    end
  end
end
