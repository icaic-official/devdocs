module Docs
  class Spacy
    class EntriesFilter < Docs::EntriesFilter
      CALLABLE_TAGS = ['method', 'function', 'classmethod', 'staticmethod', 'contextmanager', 'registered function']
      API_TAGS = CALLABLE_TAGS + ['property', 'attribute', 'class', 'cdef class', 'struct', 'decorator']
      # registered architectures, tasks and models ("spacy.Tok2Vec.v2")
      REGISTERED_NAME = /\A[\w-]+(\.\w+)+\.v\d+\z/

      def get_name
        name = at_css('h1').content.strip
        # the usage guide has the same title
        name << ' API' if slug == 'api/large-language-models'
        name
      end

      def get_type
        if slug.start_with?('usage')
          'Usage'
        else
          section = result[:spacy_section]
          section.present? && section != 'Overview' ? "API: #{section}" : 'API'
        end
      end

      # The API's classes, methods, functions and properties (the headings
      # tagged as such: "Doc.__init__ method"), CLI commands and registered
      # architectures
      def additional_entries
        return [] if slug.start_with?('usage')

        css('h2[id], h3[id], h4[id]').each_with_object([]) do |node, entries|
          tags = node.css('._spacy-tag').map(&:content)
          name = node.children.reject { |child| child['class'] == '_spacy-tag' }.map(&:content).join.strip
          next if name.blank? || name == self.name

          if tags.include?('command')
            name = "spacy #{name}"
          elsif kind = tags.find { |tag| API_TAGS.include?(tag) }
            name << '()' if CALLABLE_TAGS.include?(kind) && !name.end_with?(')')
            # the Cython classes have the names of the Python classes
            name << ' (Cython)' if slug.start_with?('api/cython') && ['cdef class', 'struct'].include?(kind)
          elsif name !~ REGISTERED_NAME
            next
          end

          entries << [name, node['id']]
        end
      end
    end
  end
end
