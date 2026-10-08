module Docs
  class H5py < UrlScraper
    self.name = 'h5py'
    self.slug = 'h5py'
    self.type = 'sphinx'
    self.root_path = 'index.html'
    self.links = {
      home: 'https://www.h5py.org/',
      code: 'https://github.com/h5py/h5py'
    }

    html_filters.push 'h5py/entries', 'h5py/clean_html', 'sphinx/clean_html'

    options[:container] = '.rst-content [itemprop="articleBody"]'
    # the guides and the high-level API; not the release notes and the
    # contributor and release guides
    options[:skip] = %w(genindex.html search.html contributing.html release_guide.html licenses.html related_projects.html)
    options[:skip_patterns] = [/\Awhatsnew/, /\A_sources/, /\A_modules/]
    options[:rate_limit] = 300

    options[:attribution] = <<-HTML
      &copy; 2008&ndash;2026 Andrew Collette and contributors<br>
      Licensed under the 3-clause BSD License.
    HTML

    version '3.16' do
      self.release = '3.16.0'
      self.base_url = "https://docs.h5py.org/en/#{release}/"
    end

    def get_latest_version(opts)
      get_latest_github_release('h5py', 'h5py', opts)
    end
  end
end
