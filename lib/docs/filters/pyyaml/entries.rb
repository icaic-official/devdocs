module Docs
  class Pyyaml
    class EntriesFilter < Docs::EntriesFilter
      def get_name
        'PyYAML'
      end

      def get_type
        'PyYAML'
      end

      def include_default_entry?
        false
      end

      # Every section, named after its heading and typed by its h2, and the
      # functions of the yaml package listed in "The yaml package"
      def additional_entries
        entries = []
        type = nil
        section = nil

        doc.children.each do |node|
          case node.name
          when 'h2'
            type = node.content.strip
            section = nil
            entries << [type, node['id'], type]
          when 'h3', 'h4'
            section = node['id']
            entries << [node.content.strip, node['id'], type]
          when 'pre'
            next unless section == 'the-yaml-package' && node['id']
            node.content.scan(/^(\w+)\(/).flatten.uniq.each do |function|
              entries << ["yaml.#{function}()", node['id'], 'Reference']
            end
          end
        end

        entries
      end
    end
  end
end
