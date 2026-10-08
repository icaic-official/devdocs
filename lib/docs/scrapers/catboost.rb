module Docs
  # catboost.ai only serves the documentation of the latest release.
  class Catboost < UrlScraper
    self.name = 'CatBoost'
    self.slug = 'catboost'
    self.type = 'catboost'
    self.base_url = 'https://catboost.ai/docs/en/'
    self.release = '1.2.10'
    self.links = {
      home: 'https://catboost.ai/',
      code: 'https://github.com/catboost/catboost'
    }

    html_filters.push 'catboost/clean_html', 'catboost/entries'

    options[:container] = 'main.dc-doc-page__content, main.dc-doc-leading-page__main'
    # only the pages listed by initial_paths
    options[:only] = []
    options[:rate_limit] = 300

    options[:attribution] = <<-HTML
      &copy; 2017&ndash;2026 YANDEX LLC<br>
      Licensed under the Apache License, Version 2.0.
    HTML

    # The packages, interfaces and topics that aren't part of the Python package
    # or the training parameters
    SKIP_PATHS = [
      %r{\A(concepts|installation)/(spark|r|cli|java|c-plus-plus)-},
      %r{\Aconcepts/(build-from-source|applying__models|apply-|export-coreml)},
      %r{\Ainstallation/build-},
      %r{\Afeatures/catboost-with-clickhouse},
      %r{\Aconcepts/(educational-materials-videos|development-and-contributions|contacts)\z}
    ]

    # The site's navigation is rendered collapsed: the pages come from the
    # list of all the pages it publishes for LLMs, in the navigation's order.
    def initial_paths
      @initial_paths ||= begin
        paths = []
        Request.run "#{self.class.base_url}llms.txt" do |response|
          raise "Failed to fetch llms.txt (#{response.code})" unless response.success?
          response.body.scan(%r{\]\(https://catboost\.ai/docs/en/([^)\s]+)\.md\)}) do |(path)|
            path = path.sub(%r{(\A|/)index\z}, '\1')
            next if path.blank? || SKIP_PATHS.any? { |pattern| path =~ pattern }
            paths << path
          end
        end
        paths.uniq
      end
    end

    def get_latest_version(opts)
      get_latest_github_release('catboost', 'catboost', opts)
    end
  end
end
