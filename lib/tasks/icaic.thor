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

    Docs.generate_manifest
    puts "Installed #{Icaic.doc_slugs.length} docs: #{Icaic.doc_slugs.join(', ')}"
  end

  desc 'build <doc> <doc@version>...', 'Scrape docs and store their packages in docs-packages'
  def build(*names)
    names.each do |name|
      system('thor', 'docs:generate', name, '--package', '--force') or abort "ERROR: failed to generate #{name}"
      doc = Docs.find(*name.split(/@|~/))
      FileUtils.mkpath(Icaic::PACKAGES_PATH)
      FileUtils.mv(File.join(Docs.store_path, "#{doc.path}.tar.gz"), Icaic.package_path(doc.path))
      puts "Stored docs-packages/#{doc.path}.tar.gz"
    end
  end

  desc 'status', 'List the appendix packages and the docs that cover them'
  def status
    Icaic.entries.each do |entry|
      state = if entry['doc'].nil? then 'MISSING'
              elsif File.exist?(Icaic.package_path(entry['doc'])) then 'package'
              else 'devdocs.io'
              end
      puts format('%-24s %-8s %-18s %s', entry['package'], entry['version'], entry['doc'] || '-', state)
    end
  end
end
