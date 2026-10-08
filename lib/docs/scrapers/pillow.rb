module Docs
  # Read the Docs builds no 12.3.0 version of the documentation: "stable" is
  # built from the 12.3.0 tag.
  class Pillow < UrlScraper
    self.name = 'Pillow'
    self.slug = 'pillow'
    self.type = 'sphinx'
    self.root_path = 'index.html'
    self.links = {
      home: 'https://python-pillow.github.io/',
      code: 'https://github.com/python-pillow/Pillow'
    }

    html_filters.push 'pillow/entries', 'pillow/clean_html', 'sphinx/clean_html'

    options[:container] = 'article[role="main"]'
    # the installation guide, the handbook and the reference; not the release
    # notes, the deprecations and the porting guide
    options[:only] = %w(index.html PIL.html)
    options[:only_patterns] = [/\Ainstallation\//, /\Ahandbook\//, /\Areference\//]
    options[:skip] = %w(genindex.html search.html py-modindex.html)
    options[:skip_patterns] = [/\A_sources/, /\A_modules/]
    options[:max_image_size] = 300_000
    options[:rate_limit] = 300

    options[:attribution] = <<-HTML
      &copy; 1997&ndash;2011 by Secret Labs AB, 1995&ndash;2011 by Fredrik Lundh and contributors, 2010 by Jeffrey A. Clark and contributors<br>
      Licensed under the MIT-CMU License.
    HTML

    version '12.3' do
      self.release = '12.3.0'
      self.base_url = 'https://pillow.readthedocs.io/en/stable/'
    end

    def get_latest_version(opts)
      get_latest_github_release('python-pillow', 'Pillow', opts)
    end
  end
end
