module Docs
  class H5py
    class EntriesFilter < Docs::EntriesFilter
      def get_name
        at_css('h1').content.delete("¶\u{f0c1}").strip
      end

      def get_type
        if slug.start_with?('high/')
          'High-level API'
        elsif %w(quick build faq).include?(slug)
          'Guide'
        else
          'Advanced topics'
        end
      end

      def include_default_entry?
        !root_page?
      end

      def additional_entries
        css('dl.py > dt[id]').map do |node|
          kind = node.parent['class'][/\bpy (\w+)/, 1]
          name = node['id'].dup
          name << '()' if %w(function method classmethod staticmethod).include?(kind)
          [name, node['id'], 'High-level API']
        end
      end
    end
  end
end
