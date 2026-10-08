module Docs
  class Xgboost
    class EntriesFilter < Docs::EntriesFilter
      def get_name
        heading_text(at_css('h1'))
      end

      def get_type
        case slug
        when 'parameter' then 'Parameters'
        when 'python/python_api' then 'Python API'
        when /\Apython\/(examples|dask-examples|survival-examples|rmm-examples)\// then 'Python Examples'
        when /\Apython\// then 'Python Package'
        when /\Atutorials\// then 'Tutorials'
        else 'Guides'
        end
      end

      def additional_entries
        return parameter_entries if slug == 'parameter'

        css('dl.py > dt[id]').each_with_object([]) do |node, entries|
          kind = node.parent['class'][/\bpy (\w+)/, 1]
          name = node['id'].dup
          name << '()' if %w(function method classmethod staticmethod).include?(kind)
          entries << [name, node['id'], api_type(node)]
        end
      end

      private

      # the headings end with the theme's link icon (U+F0C1)
      def heading_text(node)
        node.content.delete("\u{f0c1}¶").delete_suffix('#').strip
      end

      # "Python API: Scikit-Learn API" after the section of python_api.html
      def api_type(node)
        return 'Python Examples' unless slug == 'python/python_api'
        section = node.ancestors('section').map { |s| s.at_css('> h2') }.compact.first
        section ? "Python API: #{heading_text(section)}" : 'Python API'
      end

      # "Parameters for Linear Booster (booster=gblinear)" -> "Linear Booster"
      def parameter_section(node)
        heading_text(node).sub(/\s*\(.*\z/, '').sub(/\AParameters? for (using )?/, '').sub(/\A\w/, &:upcase)
      end

      # The parameters are list items starting with "``name`` [default=...]",
      # which the clean_html filter gives an id ("param-name").
      def parameter_entries
        css('li[id^="param-"]').map do |node|
          section = node.xpath('preceding::h2[1] | preceding::h3[1]').last
          type = section ? "Parameters: #{parameter_section(section)}" : 'Parameters'
          [node.at_css('code').content.strip, node['id'], type]
        end
      end
    end
  end
end
