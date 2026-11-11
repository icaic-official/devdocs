require 'base64'

module Docs
  # Embeds the images of file scrapers' documents, which are in the source
  # directory rather than on a site the images filter could download them
  # from. Insert it before clean_local_urls, which removes local images.
  class LocalImagesFilter < Filter
    include Instrumentable

    MIME_TYPES = { '.png' => 'image/png', '.jpg' => 'image/jpeg', '.jpeg' => 'image/jpeg', '.gif' => 'image/gif' }

    def self.cache
      @cache ||= {}
    end

    def call
      css('img[src^="http://localhost/"]').each do |node|
        file = File.join(context[:source_directory], URL.parse(node['src']).path.delete_prefix('/'))
        data = self.class.cache.fetch(file) { self.class.cache[file] = data_uri(file) }
        if data
          node['src'] = data
        else
          node.remove
        end
      end
      doc
    end

    private

    def data_uri(file)
      mime_type = MIME_TYPES[File.extname(file).downcase]
      return unless mime_type && File.file?(file)

      image = File.binread(file)
      if webp = Docs::ImagesFilter.convert_to_webp(image)
        image = webp
        mime_type = 'image/webp'
      end

      if image.bytesize > (context[:max_image_size] || Docs::ImagesFilter::DEFAULT_MAX_SIZE)
        instrument 'too_big.image', url: file, size: image.bytesize
        return
      end

      "data:#{mime_type};base64,#{Base64.strict_encode64(image)}"
    end
  end
end
