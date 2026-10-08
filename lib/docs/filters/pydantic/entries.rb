module Docs
  class Pydantic
    class EntriesFilter < Docs::EntriesFilter
      def get_name
        name = at_css('h1').content.strip
        # "Configuration" and "Errors" are also the names of guides
        slug.start_with?('api/') && name !~ /\Apydantic/ ? "#{name} (API)" : name
      end

      def get_type
        case slug
        when /\Aapi\/pydantic-core\// then 'API: pydantic_core'
        when /\Aapi\/pydantic_settings/ then 'API: pydantic_settings'
        when /\Aapi\// then 'API: pydantic'
        when /\Aconcepts\// then 'Concepts'
        when /\Aerrors\// then 'Errors'
        when /\Aexamples\// then 'Examples'
        else 'Get Started'
        end
      end

      def include_default_entry?
        !root_page?
      end

      def additional_entries
        if slug.start_with?('api/')
          api_entries
        elsif slug =~ /\Aerrors\/(validation|usage)_errors/
          # the error codes: "int_parsing", "class-not-fully-defined"
          css('h2[id], h3[id]').map { |node| [node['id'], node['id'], 'Errors'] }
        else
          []
        end
      end

      private

      # The headings of the members carry their qualified names
      # ("pydantic.BaseModel.model_validate"), followed by the decorators and
      # the signature
      def api_entries
        css('h2[id], h3[id], h4[id]').each_with_object([]) do |node, entries|
          id = node['id']
          next unless id =~ /\Apydantic\w*\.[\w.]+\z/
          signature = node.next_element
          signature = signature.next_element while signature && signature.name == 'p' && signature.content.strip.start_with?('@')
          is_function = signature&.name == 'pre' && signature.content =~ /\A\s*(async\s+)?def\s/
          entries << [is_function ? "#{id}()" : id, id]
        end
      end
    end
  end
end
