module Docs
  # Read the Docs builds no 1.6.0 version of the documentation: "stable" is
  # built from the 1.6.0 tag.
  class Joblib < UrlScraper
    self.name = 'joblib'
    self.slug = 'joblib'
    self.type = 'sphinx'
    self.release = '1.6.0'
    self.base_url = 'https://joblib.readthedocs.io/en/stable/'
    self.root_path = 'index.html'
    # only linked from the navigation
    self.initial_paths = %w(user_guide/index.html user_guide/installing.html user_guide/why.html)
    self.links = {
      home: 'https://joblib.readthedocs.io/',
      code: 'https://github.com/joblib/joblib'
    }

    html_filters.push 'joblib/entries', 'joblib/clean_html', 'sphinx/clean_html'

    options[:container] = 'article.bd-article'
    # the user guide, the API reference and the examples; not the change log
    # and the development notes
    options[:only] = %w(index.html references.html)
    options[:only_patterns] = [/\Auser_guide\//, /\Agenerated\//, /\Aauto_examples\//]
    options[:max_image_size] = 300_000
    options[:rate_limit] = 300

    options[:attribution] = <<-HTML
      &copy; 2008&ndash;2025 The joblib developers<br>
      Licensed under the 3-clause BSD License.
    HTML

    def get_latest_version(opts)
      get_latest_github_release('joblib', 'joblib', opts)
    end
  end
end
