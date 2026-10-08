module Docs
  class Joblib
    class EntriesFilter < Docs::EntriesFilter
      def get_name
        name = at_css('h1').content.delete('#¶').strip
        dl = at_css('dl.py')
        name << '()' if slug.start_with?('generated/') && dl && dl['class'] =~ /\bpy function\b/
        name
      end

      def get_type
        if slug.start_with?('generated/')
          'API'
        elsif slug.start_with?('auto_examples/')
          'Examples'
        else
          'User guide'
        end
      end

      def include_default_entry?
        !root_page?
      end

      # the methods and attributes of the classes
      def additional_entries
        return [] unless slug.start_with?('generated/')
        page_id = slug.sub('generated/', '')
        css('dl.py > dt[id]').each_with_object([]) do |node, entries|
          next if node['id'] == page_id
          kind = node.parent['class'][/\bpy (\w+)/, 1]
          name = node['id'].dup
          name << '()' if %w(function method classmethod staticmethod).include?(kind)
          entries << [name, node['id'], 'API']
        end
      end
    end
  end
end
