module Docs
  class PytorchLightning
    class EntriesFilter < Docs::Torchvision::EntriesFilter
      TYPE_BY_DIRECTORY = {
        'cli' => 'CLI',
        'common' => 'Common Workflows',
        'starter' => 'Getting Started',
        'levels' => 'Expertise Levels',
        'upgrade' => 'Upgrading'
      }

      def get_type
        # "api/lightning.pytorch.callbacks.EarlyStopping" -> "lightning.pytorch.callbacks"
        return name.split('.').first(3).join('.') if generated_page?
        return 'API Reference' if slug == 'api_references'

        directory = slug.include?('/') ? slug.split('/').first : nil
        return 'Guides' unless directory
        TYPE_BY_DIRECTORY[directory] || directory.split('_').map(&:capitalize).join(' ')
      end

      private

      def generated_page?
        slug.start_with?('api/')
      end
    end
  end
end
