module Docs
  class Gymnasium
    class EntriesFilter < Docs::EntriesFilter
      ENVIRONMENT_GROUPS = {
        'atari' => 'Atari', 'box2d' => 'Box2D', 'classic_control' => 'Classic Control',
        'mujoco' => 'MuJoCo', 'toy_text' => 'Toy Text'
      }

      def get_name
        at_css('h1').content.delete('¶').strip
      end

      def get_type
        section, group = slug.split('/')
        case section
        when 'api'
          case group
          when 'spaces' then 'Spaces'
          when 'wrappers' then 'Wrappers'
          when 'vector' then 'Vector'
          else 'API'
          end
        when 'environments'
          "Environments: #{ENVIRONMENT_GROUPS[group] || group.to_s.tr('_', ' ').capitalize}"
        when 'tutorials' then 'Tutorials'
        else 'Introduction'
        end
      end

      def include_default_entry?
        !root_page?
      end

      def additional_entries
        return [] unless slug.start_with?('api/')
        css('dl.py > dt[id]').map do |node|
          kind = node.parent['class'][/\bpy (\w+)/, 1]
          name = node['id'].dup
          name << '()' if %w(function method classmethod staticmethod).include?(kind)
          [name, node['id']]
        end
      end
    end
  end
end
