module Docs
  class Pillow
    class EntriesFilter < Docs::EntriesFilter
      def get_name
        name = at_css('h1').content.delete('¶').strip
        # "ImageChops (“channel operations”) module", "PixelAccess class"
        if slug.start_with?('reference/') && name =~ /\A(\w+)\b.*\b(module|class)\b/i
          "PIL.#{$1}"
        else
          name
        end
      end

      def get_type
        if slug.start_with?('reference/') && name.start_with?('PIL.')
          name
        elsif slug.start_with?('reference/') || slug == 'PIL'
          'Reference'
        elsif slug.start_with?('handbook/')
          'Handbook'
        else
          'Installation'
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
          [name, node['id'], additional_type]
        end
      end

      private

      def additional_type
        case slug
        when 'reference/plugins' then 'Plugins'
        when 'reference/internal_modules' then 'Internal modules'
        when 'PIL' then 'PIL package'
        else type
        end
      end
    end
  end
end
