require 'base64'

module Docs
  class Opencv
    # The images are in the archive, not on a site the images filter could
    # download them from: they're embedded from there before
    # clean_local_urls removes the local ones.
    class ImagesFilter < Filter
      include Instrumentable

      MIME_TYPES = { '.png' => 'image/png', '.jpg' => 'image/jpeg', '.jpeg' => 'image/jpeg', '.gif' => 'image/gif' }

      def self.cache
        @cache ||= {}
      end

      def call
        css('img[src^="http://localhost/"]').each do |node|
          path = URL.parse(node['src']).path.delete_prefix('/')
          data = self.class.cache.fetch(path) { self.class.cache[path] = data_uri(path) }
          if data
            node['src'] = data
          else
            node.remove
          end
        end
        doc
      end

      private

      def data_uri(path)
        mime_type = MIME_TYPES[File.extname(path).downcase]
        file = File.join(context[:source_directory], path)
        return unless mime_type && File.file?(file)

        image = File.binread(file)
        if webp = Docs::ImagesFilter.convert_to_webp(image)
          image = webp
          mime_type = 'image/webp'
        end

        if image.bytesize > context[:max_image_size]
          instrument 'too_big.image', url: path, size: image.bytesize
          return
        end

        "data:#{mime_type};base64,#{Base64.strict_encode64(image)}"
      end
    end
  end
end
