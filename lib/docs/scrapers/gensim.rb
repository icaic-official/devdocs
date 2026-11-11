module Docs
  # radimrehurek.com/gensim only serves the documentation of 4.3.3, so the
  # documentation of the 4.4 release is built from its sources (see
  # docs/file-scrapers.md).
  class Gensim < FileScraper
    self.name = 'gensim'
    self.slug = 'gensim'
    self.type = 'sphinx'
    self.release = '4.4.0'
    self.root_path = 'apiref.html'
    self.initial_paths = %w(intro.html auto_examples/core/index.html auto_examples/tutorials/index.html)
    self.links = {
      home: 'https://radimrehurek.com/gensim/',
      code: 'https://github.com/piskvorky/gensim'
    }

    html_filters.insert_before 'clean_local_urls', 'local_images'
    html_filters.push 'gensim/clean_html', 'gensim/entries', 'sphinx/math', 'sphinx/clean_html'

    options[:container] = '.rst-content [itemprop="articleBody"]'
    # the API reference and the core tutorials and tutorials; not the how-to
    # guides and other examples, the test package or the support pages
    options[:only] = %w(intro.html interfaces.html utils.html matutils.html downloader.html)
    options[:only_patterns] = [
      /\A(models|corpora|similarities|parsing|scripts|topic_coherence)\//,
      /\Aauto_examples\/(core|tutorials)\//
    ]
    options[:skip_patterns] = [/\A_modules/, /\A_sources/, /\A_downloads/, /\.(py|ipynb|zip)\z/]
    options[:max_image_size] = 300_000

    options[:attribution] = <<-HTML
      &copy; 2009&ndash;2025 Radim Řehůřek<br>
      Licensed under the GNU LGPLv2.1 license.
    HTML

    def get_latest_version(opts)
      get_latest_github_release('piskvorky', 'gensim', opts)
    end
  end
end
