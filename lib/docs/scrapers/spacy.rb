module Docs
  # spacy.io only serves the documentation of the latest release.
  class Spacy < UrlScraper
    self.name = 'spaCy'
    self.slug = 'spacy'
    self.type = 'spacy'
    self.release = '3.8.16'
    self.base_url = 'https://spacy.io/'
    self.root_path = 'api'
    # api/attributes is only linked from the navigation
    self.initial_paths = %w(usage api/attributes)
    self.links = {
      home: 'https://spacy.io/',
      code: 'https://github.com/explosion/spaCy'
    }

    # the code filter reads the page's MDX, outside of the container
    html_filters.insert_before 'container', 'spacy/code'
    html_filters.push 'spacy/clean_html', 'spacy/entries'

    options[:container] = 'main > article'
    # the API reference and the usage guides; not the release notes ("What's
    # New in v3.x"), the models directory or the Universe
    options[:only_patterns] = [/\Aapi\//, /\Ausage(\/|\z)/]
    # api/annotation and usage/examples redirect to api/data-formats and usage/projects
    options[:skip] = %w(api/annotation usage/examples)
    options[:skip_patterns] = [/\Ausage\/v\d/]
    options[:max_image_size] = 300_000
    options[:rate_limit] = 300

    options[:attribution] = <<-HTML
      &copy; 2016&ndash;2025 Explosion AI GmbH<br>
      Licensed under the MIT License.
    HTML

    def get_latest_version(opts)
      get_latest_github_release('explosion', 'spaCy', opts)
    end
  end
end
