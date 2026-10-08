module Docs
  class SentenceTransformers
    class EntriesFilter < Docs::EntriesFilter
      SECTIONS = {
        'sentence_transformer' => 'Sentence Transformer',
        'cross_encoder' => 'Cross Encoder',
        'sparse_encoder' => 'Sparse Encoder',
        'multi_vector_encoder' => 'Multi-Vector Encoder',
        'base' => 'Base',
        'util' => 'Util'
      }

      def get_name
        # the headings end with the theme's link icon (U+F0C1)
        at_css('h1').content.delete("\u{f0c1}¶").delete_suffix('#').strip
      end

      # "Sentence Transformer: Losses" for the API reference, the section of the
      # site for the guides ("Cross Encoder"), and "Examples: ..." for the
      # READMEs of the training and application examples.
      def get_type
        parts = slug.split('/')
        if slug.start_with?('docs/package_reference/')
          section = SECTIONS.fetch(parts[2], parts[2].to_s.titleize)
          parts[3] == 'index' || parts.length < 4 ? "Reference: #{section}" : "#{section}: #{name}"
        elsif slug.start_with?('examples/')
          "Examples: #{SECTIONS.fetch(parts[1], parts[1].to_s.titleize)}"
        else
          SECTIONS.fetch(parts[1], 'Getting Started')
        end
      end

      def additional_entries
        css('dl.py > dt[id]').each_with_object([]) do |node, entries|
          kind = node.parent['class'][/\bpy (\w+)/, 1]
          name = node.at_css('.sig-name')&.content&.strip
          next if name.blank?
          parent = node.parent.ancestors('dl.py').first&.at_css('> dt .sig-name')&.content&.strip
          name = "#{parent}.#{name}" if parent
          name << '()' if %w(function method classmethod staticmethod).include?(kind)
          entries << [name, node['id']]
        end
      end
    end
  end
end
