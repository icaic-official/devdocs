require 'yaml'

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
end
