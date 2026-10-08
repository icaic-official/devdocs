module Docs
  # Scraped from the HTML archive docs.scipy.org publishes for each release.
  class Scipy < FileScraper
    self.name = 'SciPy'
    self.slug = 'scipy'
    self.type = 'sphinx'
    self.root_path = 'index.html'
    self.links = {
      home: 'https://scipy.org/',
      code: 'https://github.com/scipy/scipy'
    }

    html_filters.push 'scipy/entries', 'scipy/clean_html', 'sphinx/math', 'sphinx/clean_html'

    options[:container] = '.bd-article'
    # the API reference and the user guide; not the building and contributor
    # guides or the release notes
    options[:only_patterns] = [/\Areference\//, /\Atutorial\//]
    options[:skip] = %w(tutorial/_LaTeXMathMacros.html reference/generated/scipy.test.html reference/generated/scipy.show_config.html)
    options[:skip_patterns] = [/.*(?<!\.html)\z/]
    options[:max_image_size] = 300_000

    options[:attribution] = <<-HTML
      &copy; 2001&ndash;2026 SciPy Developers<br>
      Licensed under the 3-clause BSD License.
    HTML

    version '1.18' do
      self.release = '1.18.0'
      self.base_url = "https://docs.scipy.org/doc/scipy-#{release}/"
    end

    def get_latest_version(opts)
      get_latest_github_release('scipy', 'scipy', opts)
    end

    private

    def download_source
      download_and_extract("https://docs.scipy.org/doc/scipy-#{self.class.release}/scipy-html-#{self.class.release}.zip")
      rename_case_collisions
    end

    # DevDocs paths are case-insensitive, and pages such as
    # scipy.stats.Logistic (the class) and scipy.stats.logistic (the
    # distribution) would be stored at the same one: the class pages get a
    # "-class" suffix (dropped from the entry names) and the links to them
    # are updated.
    def rename_case_collisions
      directory = File.join(source_directory, 'reference', 'generated')
      pages = Dir.children(directory).select { |name| name.end_with?('.html') }
      renames = pages.group_by(&:downcase).values.select { |group| group.length > 1 }.flat_map do |group|
        group.reject { |name| name == name.downcase }.map { |name| [name, name.sub(/\.html\z/, '-class.html')] }
      end
      return if renames.empty?

      renames.each { |from, to| File.rename(File.join(directory, from), File.join(directory, to)) }
      pattern = Regexp.union(renames.map { |from, _| %r{(?<=["/])#{Regexp.escape(from)}(?=["#])} })
      replacements = renames.to_h

      Dir.glob(File.join(source_directory, '**', '*.html')).each do |path|
        html = File.read(path)
        next unless renames.any? { |from, _| html.include?(from) }
        File.write(path, html.gsub(pattern) { |match| replacements[match] })
      end
    end
  end
end
