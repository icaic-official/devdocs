module Docs
  class Lightgbm
    class EntriesFilter < Docs::EntriesFilter
      def get_name
        if api_page?
          css('dl.py.function > dt[id]').any? { |node| node['id'] == page_object } ? "#{page_object}()" : page_object
        else
          heading_text(at_css('h1'))
        end
      end

      def get_type
        case slug
        when 'Parameters' then 'Parameters'
        when 'Python-API' then 'Python API'
        when /\Apythonapi\// then 'Python API'
        else 'Guides'
        end
      end

      def additional_entries
        return parameter_entries if slug == 'Parameters'
        return [] unless api_page?

        css('dl.py > dt[id]').each_with_object([]) do |node, entries|
          id = node['id']
          next if id == page_object
          kind = node.parent['class'][/\bpy (\w+)/, 1]
          name = %w(function method classmethod staticmethod).include?(kind) ? "#{id}()" : id
          entries << [name, id, "Python API: #{page_object}"]
        end
      end

      private

      # the headings end with the theme's link icon (U+F0C1)
      def heading_text(node)
        node.content.delete("\u{f0c1}¶").delete_suffix('#').strip
      end

      # "pythonapi/lightgbm.Booster" documents lightgbm.Booster
      def api_page?
        slug.start_with?('pythonapi/')
      end

      def page_object
        slug.delete_prefix('pythonapi/')
      end

      # The clean_html filter moves the parameters' anchors to their list items
      def parameter_entries
        css('li[id]').map do |node|
          section = node.xpath('preceding::h2[1]').last
          type = section ? "Parameters: #{heading_text(section)}" : 'Parameters'
          [node['id'], node['id'], type]
        end
      end
    end
  end
end
