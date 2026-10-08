module Docs
  class Huggingface
    # The guides are listed under the top-level section of the table of contents
    # they're in. The pages documenting objects make up a type of their own,
    # with the classes, functions and methods they document; the scrapers can
    # prefix the names of those types per directory or section of the table of
    # contents (options[:type_prefixes]).
    class EntriesFilter < Docs::EntriesFilter
      def get_name
        at_css('h1')&.content&.strip.presence || slug.split('/').last.titleize
      end

      def get_type
        return api_type if api_page?
        sections.first.presence || 'Guides'
      end

      def additional_entries
        css('dl.hf-docstring > dt[id]').map do |node|
          id = node['id']
          # every object is in the package: "BertModel.forward()", not "transformers.BertModel.forward()"
          name = id.delete_prefix("#{context[:package]}.")
          name = "#{name}()" unless node.parent['class'].include?('hf-class')
          [name, id, api_type]
        end
      end

      private

      def api_page?
        at_css('dl.hf-docstring > dt[id]').present?
      end

      def api_type
        prefix = context[:type_prefixes].to_h.find { |key, _| slug.start_with?(key) || sections.include?(key) }&.last
        prefix ? "#{prefix}: #{name}" : name
      end

      def sections
        toctree = context[:toctree] || {}
        toctree[slug] || toctree.find { |path, _| path.downcase == slug.downcase }&.last || []
      end
    end
  end
end
