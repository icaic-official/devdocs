module Docs
  # The PyYAML documentation is a single wiki page, which isn't versioned; it
  # documents the 6.0 releases (the latest is 6.0.3).
  class Pyyaml < UrlScraper
    self.name = 'PyYAML'
    self.slug = 'pyyaml'
    self.type = 'simple'
    self.release = '6.0.3'
    self.base_url = 'https://pyyaml.org/wiki/PyYAMLDocumentation'
    self.links = {
      home: 'https://pyyaml.org/',
      code: 'https://github.com/yaml/pyyaml'
    }

    html_filters.push 'pyyaml/clean_html', 'pyyaml/entries'

    options[:container] = 'body'
    options[:skip_links] = true

    options[:attribution] = <<-HTML
      &copy; 2017&ndash;2021 Ingy döt Net, 2006&ndash;2016 Kirill Simonov<br>
      Licensed under the MIT License.
    HTML

    def get_latest_version(opts)
      get_github_tags('yaml', 'pyyaml', opts)[0]['name']
    end
  end
end
