require 'yaml'
require 'json'
require 'base64'
require 'cgi'

# The ICAIC 2026 documentation selection, read from config/icaic_docs.yml.
module Icaic
  CONFIG_PATH = File.expand_path('../config/icaic_docs.yml', __dir__)
  PACKAGES_PATH = File.expand_path('../docs-packages', __dir__)

  def self.entries
    YAML.load_file(CONFIG_PATH)
  end

  # The DevDocs slugs ("name" or "name~version") of every installed doc.
  def self.doc_slugs
    entries.map { |entry| entry['doc'] }.compact.uniq
  end

  def self.package_path(slug)
    File.join(PACKAGES_PATH, "#{slug}.tar.gz")
  end

  # Images larger than this, even as lossy WebP, stay remote.
  MAX_IMAGE_SIZE = 5_000_000

  # Where to look for an image when its URL is broken: the devdocs.io pandas
  # package points to the 3.0.8 docs, which pandas.pydata.org doesn't serve.
  IMAGE_URL_FALLBACKS = {
    %r{\Ahttps://pandas\.pydata\.org/pandas-docs/version/[\d.]+/} => 'https://pandas.pydata.org/docs/'
  }

  # Makes the images of an installed doc work without internet access: embeds
  # the remote ones (those a scraper left remote, being bigger than its
  # max_image_size, and those of the docs downloaded from devdocs.io) as data
  # URLs, and drops srcset attributes, which point to images that aren't part of
  # the doc (browsers would show those instead of the src). Returns the URLs
  # that couldn't be embedded.
  def self.make_images_offline(dir)
    db_path = File.join(dir, 'db.json')
    db = JSON.parse(File.read(db_path))
    srcs = db.values.flat_map { |html| html.scan(/<img\b[^>]*?\ssrc="(https?:[^"]+)"/).flatten }.uniq
    return [] if srcs.empty? && db.values.none? { |html| html.match?(IMG_SRCSET) }

    images = fetch_images(srcs)
    remote_src = /(<img\b[^>]*?\ssrc=")(https?:[^"]+)(")/
    replace = lambda do |html|
      html = html.gsub(remote_src) { images[$2] ? "#{$1}#{images[$2]}#{$3}" : $& }
      html.gsub(IMG_SRCSET, '\\1')
    end

    db.each do |path, html|
      next unless html.match?(remote_src) || html.match?(IMG_SRCSET)
      db[path] = replace.(html)
      page_path = File.join(dir, "#{path}.html")
      File.write(page_path, replace.(File.read(page_path))) if File.exist?(page_path)
    end
    json = db.to_json
    File.write(db_path, json)

    meta_path = File.join(dir, 'meta.json')
    meta = JSON.parse(File.read(meta_path))
    meta['db_size'] = json.bytesize
    File.write(meta_path, meta.to_json)

    srcs - images.keys
  end

  IMG_SRCSET = /(<img\b[^>]*?)\ssrcset="[^"]*"/

  # { src => data URL } for the srcs (HTML-escaped image URLs) that could be
  # fetched. Failed requests are retried, more slowly, as some hosts
  # (huggingface.co) rate-limit.
  def self.fetch_images(srcs)
    images = {}
    [8, 2, 1].each_with_index do |concurrency, round|
      pending = srcs - images.keys
      break if pending.empty?
      sleep 10 * round
      hydra = Typhoeus::Hydra.new(max_concurrency: concurrency)
      pending.each do |src|
        urls = [CGI.unescapeHTML(src)]
        IMAGE_URL_FALLBACKS.each { |pattern, replacement| urls << urls.first.sub(pattern, replacement) if urls.first.match?(pattern) }
        queue_image_request(hydra, urls) { |data_url| images[src] = data_url }
      end
      hydra.run
    end
    images
  end

  def self.queue_image_request(hydra, urls, &block)
    request = Typhoeus::Request.new(urls.first, followlocation: true, timeout: 120,
                                    headers: { 'User-Agent' => 'DevDocs' })
    request.on_complete do |response|
      data_url = response.success? && image_data_url(response)
      if data_url
        block.call(data_url)
      elsif urls.length > 1
        queue_image_request(hydra, urls.drop(1), &block)
      end
    end
    hydra.queue(request)
  end

  # Lossy WebP for the images too big to embed as they are (a few photos and
  # animations of the Hugging Face docs), still pictures scaled to 1600px wide.
  SHRINK_COMMANDS = {
    still: %w(cwebp -quiet -q 80 -resize 1600 0 -m 6 -metadata none -o - -- -),
    animation: %w(gif2webp -quiet -lossy -q 70 -m 6 -metadata none -o - -- -)
  }

  def self.image_data_url(response)
    data = response.body
    type = response.headers['Content-Type'].to_s.split(';').first.to_s.strip
    # some hosts serve images as binary/octet-stream
    type = sniff_image_type(data) unless type.start_with?('image/')
    return unless type

    if data.bytesize > MAX_IMAGE_SIZE
      command = Docs::ImagesFilter.gif?(data) ? SHRINK_COMMANDS[:animation] : SHRINK_COMMANDS[:still]
      data = IO.popen(command, 'r+b', err: File::NULL) { |io| io.write(data); io.close_write; io.read }
      return unless $?.success? && !data.empty? && data.bytesize <= MAX_IMAGE_SIZE
      type = 'image/webp'
    elsif (webp = Docs::ImagesFilter.convert_to_webp(data))
      data, type = webp, 'image/webp'
    end

    "data:#{type};base64,#{Base64.strict_encode64(data)}"
  rescue SystemCallError
    nil
  end

  def self.sniff_image_type(data)
    if Docs::ImagesFilter.starts_with?(data, Docs::ImagesFilter::PNG_SIGNATURE) then 'image/png'
    elsif Docs::ImagesFilter.gif?(data) then 'image/gif'
    elsif Docs::ImagesFilter.starts_with?(data, Docs::ImagesFilter::JPEG_SIGNATURE) then 'image/jpeg'
    elsif data.byteslice(0, 4) == 'RIFF' && data.byteslice(8, 4) == 'WEBP' then 'image/webp'
    end
  end
end
