module Docs
  class Nltk
    class EntriesFilter < Docs::EntriesFilter
      # "nltk.tokenize.punkt module", "nltk.tokenize package"
      def get_name
        heading_text(at_css('h1')).sub(/ (module|package)\z/, '')
      end

      def get_type
        if slug.start_with?('api/')
          # the top-level subpackage: "nltk.tokenize"
          name.split('.').first(2).join('.')
        elsif slug.start_with?('howto')
          'HOWTOs'
        else
          'Guides'
        end
      end

      def additional_entries
        css('dl.py > dt[id]').each_with_object([]) do |node, entries|
          kind = node.parent['class'][/\bpy (\w+)/, 1]
          name = node['id'].dup
          name << '()' if %w(function method classmethod staticmethod).include?(kind)
          entries << [name, node['id']]
        end
      end

      private

      def heading_text(node)
        node.content.delete("\u{f0c1}¶").strip
      end
    end
  end
end
