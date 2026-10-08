module Docs
  class Jupyterlab
    class EntriesFilter < Docs::EntriesFilter
      def get_name
        at_css('h1').content.delete('#¶').strip
      end

      def get_type
        if slug.start_with?('getting_started/')
          'Getting Started'
        elsif slug.start_with?('extension/')
          'Extension Development'
        else
          'User Guide'
        end
      end

      def include_default_entry?
        !root_page? && slug != 'user/index'
      end

      # the sections of the User Guide pages
      def additional_entries
        return [] unless slug.start_with?('user/') && slug != 'user/index'
        css('h2[id], section[id] > h2').map do |node|
          id = node['id'] || node.parent['id']
          ["#{name}: #{node.content.delete('#¶').strip}", id]
        end
      end
    end
  end
end
