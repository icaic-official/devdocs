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

      # the sections of the User Guide pages, and the command IDs listed in
      # "Commands" ("application:close")
      def additional_entries
        return [] unless slug.start_with?('user/') && slug != 'user/index'
        entries = css('h2[id], section[id] > h2').map do |node|
          id = node['id'] || node.parent['id']
          ["#{name}: #{node.content.delete('#¶').strip}", id]
        end
        if slug == 'user/commands'
          css('section[id] > h4:has(> code:first-child)').each do |node|
            entries << [node.at_css('code').content.strip, node.parent['id'], 'Commands']
          end
        end
        entries
      end
    end
  end
end
