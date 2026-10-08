module Docs
  class Gensim
    class EntriesFilter < Docs::EntriesFilter
      # "models.word2vec – Word2vec embeddings" -> "models.word2vec"
      def get_name
        heading = at_css('h1')
        code = heading.at_css('code')
        code ? code.content.strip : heading_text(heading)
      end

      def get_type
        case slug
        when /\Aauto_examples\/core\// then 'Core Tutorials'
        when /\Aauto_examples\// then 'Tutorials'
        when 'intro' then 'Guides'
        when /\A(\w+)\// then $1
        else 'gensim'
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
