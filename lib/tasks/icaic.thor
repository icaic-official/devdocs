class IcaicCLI < Thor
  include Thor::Actions

  def self.to_s
    'ICAIC'
  end

  def initialize(*args)
    require 'docs'
    require 'icaic'
    super
  end

  desc 'install', 'Install exactly the docs listed in config/icaic_docs.yml, removing any other'
  def install
    FileUtils.rm_rf(Docs.store_path)
    FileUtils.mkpath(Docs.store_path)

    remote = Icaic.doc_slugs.reject do |slug|
      next false unless File.exist?(Icaic.package_path(slug))
      puts "Unpacking #{slug} from docs-packages..."
      Docs::Archive.unpack(Icaic.package_path(slug), File.join(Docs.store_path, slug))
      true
    end

    if remote.any?
      puts "Downloading #{remote.join(', ')} from downloads.devdocs.io..."
      system('thor', 'docs:download', *remote)
    end

    missing = Icaic.doc_slugs.reject { |slug| File.exist?(File.join(Docs.store_path, slug, 'meta.json')) }
    abort "ERROR: failed to install #{missing.join(', ')}" if missing.any?

    Icaic.doc_slugs.each do |slug|
      failed = Icaic.make_images_offline(File.join(Docs.store_path, slug))
      failed.each { |src| puts "WARNING: #{slug}: couldn't embed #{src}" }
    end

    Docs.generate_manifest
    puts "Installed #{Icaic.doc_slugs.length} docs: #{Icaic.doc_slugs.join(', ')}"
  end

  desc 'build <doc> <doc@version>... [--jobs N]', 'Scrape docs and store their packages in docs-packages'
  option :jobs, type: :numeric, default: 1, aliases: '-j', desc: 'Number of processes used to parse the pages (file scrapers only)'
  def build(*names)
    names.each do |name|
      system('thor', 'docs:generate', name, '--package', '--force', '--jobs', options[:jobs].to_s) or abort "ERROR: failed to generate #{name}"
      doc = Docs.find(*name.split(/@|~/))
      FileUtils.mkpath(Icaic::PACKAGES_PATH)
      FileUtils.mv(File.join(Docs.store_path, "#{doc.path}.tar.gz"), Icaic.package_path(doc.path))
      puts "Stored docs-packages/#{doc.path}.tar.gz"
    end
  end

  # The app's server only renders a handful of pages, and everything else is
  # static files, so the whole app fits a static host like GitHub Pages: the
  # pages are rendered once here, and deep links (which have no file) go
  # through 404.html, which hands the path to the app in the URL's hash.
  #
  # Run after `thor icaic:install` and `thor assets:compile`, with the same
  # BASE_PATH as the assets were compiled with.
  desc 'export_pages <dir> --url=<url>', 'Export the installed docs and the app as a static site'
  option :url, required: true, desc: 'URL the site is served at, e.g. https://example.github.io/devdocs'
  def export_pages(dir)
    url = options[:url].chomp('/')
    base_path = URI(url).path
    abort "ERROR: BASE_PATH (#{ENV['BASE_PATH'].inspect}) must match the URL's path (#{base_path.inspect})" unless ENV['BASE_PATH'].to_s.chomp('/') == base_path

    ENV['RACK_ENV'] = 'production'
    ENV['FORCE_SSL'] = 'false'
    ENV['SELF_HOSTED'] = 'true'
    ENV['DOCS_ORIGIN'] = '/docs'
    require 'app'
    abort 'ERROR: compile the assets first (thor assets:compile)' unless File.exist?(App.assets_manifest_path)
    config = File.read(File.join(App.assets_path, Sprockets::Manifest.new(nil, App.assets_manifest_path).assets['app/config.js']))
    abort "ERROR: compile the assets with DOCS_ORIGIN=/docs, BASE_PATH=#{base_path} and SELF_HOSTED=true" unless config.match?(/docs_origin:\s*["']#{Regexp.escape(App.docs_origin)}["']/) && config.match?(/base_path:\s*["']#{Regexp.escape(base_path)}["']/) && config.match?(/self_hosted:\s*(true|!0)/)

    FileUtils.rm_rf(dir)
    FileUtils.mkpath(dir)
    public = App.public_folder
    %w(assets docs images favicon.ico manifest.json mathml.css robots.txt).each do |name|
      FileUtils.cp_r(File.join(public, name), dir)
    end
    # Each doc is stored twice: as one file per page, which the app loads as
    # it browses, and as db.json, which it downloads to install the doc for
    # offline use. Pages caps a site at 1 GB, which the two together exceed.
    Dir[File.join(dir, 'docs', '*', 'db.json')].each { |file| File.delete(file) } if ENV['OFFLINE_DATA'] == 'false'

    request = Rack::MockRequest.new(App)
    host = URI(url).host
    render = lambda do |path|
      response = request.get("#{base_path}#{path}", 'HTTP_HOST' => host, 'SCRIPT_NAME' => base_path, 'PATH_INFO' => path, 'rack.url_scheme' => 'https')
      abort "ERROR: #{path} rendered #{response.status}" unless response.ok?
      response.body
    end

    index = render.('/')
    File.write(File.join(dir, 'index.html'), index)
    # Pages serves /settings from settings.html, so the app's own pages load
    # directly instead of going through 404.html.
    %w(settings offline about news help).each { |page| File.write(File.join(dir, "#{page}.html"), index) }
    File.write(File.join(dir, 'service-worker.js'), render.('/service-worker.js'))
    File.write(File.join(dir, '404.html'), <<~HTML)
      <!DOCTYPE html>
      <html lang="en">
      <head>
        <meta charset="utf-8">
        <title>DevDocs</title>
        <script>
          // Pages has no file for an app path like /python~3.13/library/os, so
          // it lands here. Hand it to the app, which reads it back off the hash.
          var base = #{base_path.to_json};
          var path = location.pathname;
          if (path.indexOf(base + '/') === 0) {
            location.replace(base + '/#/' + path.slice(base.length) + location.search + location.hash);
          }
        </script>
      </head>
      <body>Page not found. <a href="#{base_path}/">Go to DevDocs</a>.</body>
      </html>
    HTML
    File.write(File.join(dir, 'opensearch.xml'),
      File.read(File.join(public, 'opensearch.xml')).gsub('https://devdocs.io', url))
    # Otherwise Pages runs the site through Jekyll, which drops files and
    # directories whose names start with an underscore.
    FileUtils.touch(File.join(dir, '.nojekyll'))

    size = Dir[File.join(dir, '**', '*')].sum { |file| File.file?(file) ? File.size(file) : 0 }
    puts "Exported #{Icaic.doc_slugs.length} docs to #{dir} (#{(size / 1024.0 / 1024).round} MB) for #{url}"
  end

  desc 'status', 'List the appendix packages and the docs that cover them'
  def status
    mismatched = false
    Icaic.entries.each do |entry|
      state = if entry['doc'].nil? then 'MISSING'
              elsif File.exist?(Icaic.package_path(entry['doc'])) then 'package'
              else 'devdocs.io'
              end
      # The release of the installed doc, which has to be of the listed
      # version: 3.0.6 is of 3.0, 3.1.1 isn't.
      meta = entry['doc'] && File.join(Docs.store_path, entry['doc'], 'meta.json')
      if meta && File.exist?(meta)
        release = JSON.parse(File.read(meta))['release'].to_s
        unless release == entry['version'] || release.start_with?("#{entry['version']}.")
          mismatched = true
          release += ' (NOT OF THE LISTED VERSION)'
        end
      end
      puts format('%-24s %-8s %-26s %-11s %s', entry['package'], entry['version'], entry['doc'] || '-', state, release || 'not installed')
    end
    exit 1 if mismatched
  end
end
