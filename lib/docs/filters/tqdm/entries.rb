module Docs
  class Tqdm
    class EntriesFilter < Docs::EntriesFilter
      def get_name
        if root_page?
          'tqdm'
        elsif slug.start_with?('dev/warnings')
          'tqdm warnings'
        else
          at_css('h1').content.delete('#¶').strip
        end
      end

      def get_type
        root_page? ? 'Guide' : 'API'
      end

      def include_default_entry?
        !root_page?
      end

      def additional_entries
        root_page? ? readme_entries : api_entries
      end

      private

      def readme_entries
        css('h3[id], h4[id]').map do |node|
          [node.content.strip, node['id'], 'Guide']
        end
      end

      # The headings carry the qualified names (see the clean_html filter) and
      # are followed by the signature: "def update(n=1)"
      def api_entries
        css('h2[id], h3[id], h4[id], h5[id]').each_with_object([]) do |node, entries|
          name = node['id']
          next unless name.include?('.') && name != slug_module
          signature = node.next_element&.content.to_s.lstrip
          name += '()' if signature =~ /^\s*(async\s+)?def\s/ && signature !~ /\A@property/
          entries << [name, node['id']]
        end
      end

      def slug_module
        at_css('h1').content.delete('#¶').strip
      end
    end
  end
end
