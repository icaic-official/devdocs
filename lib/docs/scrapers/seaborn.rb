module Docs
  # seaborn.pydata.org serves the 0.13.2 documentation at its root (the
  # archive only holds the earlier minor versions).
  class Seaborn < UrlScraper
    self.name = 'seaborn'
    self.slug = 'seaborn'
    self.type = 'sphinx'
    self.release = '0.13.2'
    self.base_url = 'https://seaborn.pydata.org/'
    self.root_path = 'index.html'
    self.links = {
      home: 'https://seaborn.pydata.org/',
      code: 'https://github.com/mwaskom/seaborn'
    }

    html_filters.push 'seaborn/entries', 'seaborn/clean_html', 'sphinx/clean_html'

    options[:container] = 'article.bd-article'
    # the installation guide, the tutorial, the API reference and the FAQ; not
    # the example gallery, the release notes or the citing page
    options[:only] = %w(index.html installing.html tutorial.html api.html faq.html)
    options[:only_patterns] = [/\Atutorial\/[\w-]+\.html\z/, /\Agenerated\/seaborn\.[\w.]+\.html\z/]
    # a few of the pair plots are larger
    options[:max_image_size] = 1_000_000
    options[:rate_limit] = 300

    options[:attribution] = <<-HTML
      &copy; 2012&ndash;2024 Michael Waskom<br>
      Licensed under the 3-clause BSD License.
    HTML

    def get_latest_version(opts)
      get_latest_github_release('mwaskom', 'seaborn', opts)
    end
  end
end
