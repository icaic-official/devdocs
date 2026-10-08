module Docs
  class Pyarrow
    class EntriesFilter < Docs::EntriesFilter
      def get_name
        if api_page?
          name = slug.split('/').last
          name << '()' if callable?(at_css('dl.py'))
          name
        elsif slug.start_with?('api/')
          "API: #{heading}"
        else
          heading
        end
      end

      def get_type
        if slug.start_with?('api/') || api_page?
          section = at_css('.bd-sidebar li.toctree-l3.current > a')
          section ? section.content.strip : 'API Reference'
        elsif slug == 'api'
          'API Reference'
        else
          'User Guide'
        end
      end

      def include_default_entry?
        !root_page?
      end

      # the methods and attributes of the classes
      def additional_entries
        return [] unless api_page?

        css('.bd-article dl.py:not(.class):not(.function) > dt[id]').map do |node|
          name = node['id']
          name += '()' if callable?(node.parent)
          [name, node['id']]
        end
      end

      private

      def heading
        at_css('h1').content.strip.delete_suffix('#').strip
      end

      def api_page?
        slug.start_with?('generated/')
      end

      def callable?(dl)
        dl && dl['class'] =~ /\b(function|method|classmethod|staticmethod)\b/
      end
    end
  end
end
