module Docs
  class Albumentations
    class EntriesFilter < Docs::EntriesFilter
      def get_name
        at_css('h1').content
      end

      # The group of the module, set by api_reference.py
      def get_type
        at_css('h1')['data-type']
      end

      def include_default_entry?
        false
      end

      # The exported classes and functions, named as they're used
      # (`A.HorizontalFlip`)
      def additional_entries
        return [] if root_page?
        css('h2[id]').map { |node| [node.content, node['id']] }
      end
    end
  end
end
