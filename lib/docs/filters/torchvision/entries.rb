module Docs
  # Entries for the domain libraries documented with the PyTorch Sphinx theme
  # (torchvision, torchaudio, PyTorch Lightning).
  class Torchvision
    class EntriesFilter < Docs::EntriesFilter
      def get_name
        # Autosummary pages ("generated/torchvision.utils.make_grid.html") are
        # named after the object they document.
        if generated_page?
          function = css('dl.py.function > dt[id]').any? { |node| node['id'] == page_object }
          return function ? "#{page_object}()" : page_object
        end
        at_css('h1').content.delete_suffix('#').delete("¶").strip
      end

      def get_type
        return 'Tutorials' if slug.start_with?('tutorials/')
        breadcrumbs.length > 2 ? breadcrumbs[1] : name
      end

      def additional_entries
        css('dl.py > dt[id]').each_with_object([]) do |node, entries|
          id = node['id']
          next if id == page_object
          # the index page has no type of its own: use the package's name
          type = id.split('.').first if root_page?
          case node.parent['class']
          when /\bpy (function|method|classmethod|staticmethod)\b/
            entries << ["#{id}()", id, type]
          when /\bpy (class|exception|attribute|property|data)\b/
            entries << [id, id, type]
          end
        end
      end

      private

      def generated_page?
        slug.include?('generated/')
      end

      def page_object
        slug.split('/').last if generated_page?
      end

      # Docs > Section > Page
      def breadcrumbs
        @breadcrumbs ||= css('.pytorch-breadcrumbs > li:not(.pytorch-breadcrumbs-aside)').map do |node|
          node.content.strip.delete_suffix('>').strip
        end.reject(&:empty?)
      end
    end
  end
end
