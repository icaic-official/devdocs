module Docs
  # docs.pydantic.dev moved to pydantic.dev/docs/validation/ (an Astro
  # Starlight site), where /2.13/ redirects to /latest/, which documents
  # v2.13.4.
  class Pydantic < UrlScraper
    self.name = 'Pydantic'
    self.slug = 'pydantic'
    self.type = 'simple'
    self.root_path = 'get-started/'
    self.initial_paths = %w(get-started/install/ get-started/why/ get-started/migration/ concepts/models/
                            api/pydantic/base_model/ errors/errors/ examples/custom_validators/)
    self.links = {
      home: 'https://pydantic.dev/docs/validation/latest/',
      code: 'https://github.com/pydantic/pydantic'
    }

    html_filters.push 'pydantic/clean_html', 'pydantic/entries'

    options[:container] = 'main'
    # Getting started, the concepts, the API reference of pydantic,
    # pydantic-core and pydantic-settings, the errors and the examples; not
    # the changelog, the contribution and support pages, the integrations,
    # the internals and the reference of the separate pydantic-extra-types
    # package
    options[:only] = %w(get-started/ get-started/install/ get-started/why/ get-started/migration/)
    options[:only_patterns] = [/\Aconcepts\/\w+\/\z/, /\Aapi\/(pydantic|pydantic-core)\/\w+\/\z/, /\Aapi\/pydantic_settings\/\z/,
                               /\Aerrors\/\w+\/\z/, /\Aexamples\/\w+\/\z/]
    options[:fix_urls] = ->(url) do
      url.sub(%r{\Ahttps://pydantic\.dev/docs/validation/(?:dev|[\d.]+)/}, 'https://pydantic.dev/docs/validation/latest/')
         .sub(%r{\Ahttps://docs\.pydantic\.dev/latest/(?!llms)}, 'https://pydantic.dev/docs/validation/latest/')
    end
    options[:rate_limit] = 300

    options[:attribution] = <<-HTML
      &copy; 2017&ndash;2026 Pydantic Services Inc. and individual contributors<br>
      Licensed under the MIT License.
    HTML

    version '2.13' do
      self.release = '2.13.4'
      self.base_url = 'https://pydantic.dev/docs/validation/latest/'
    end

    def get_latest_version(opts)
      get_latest_github_release('pydantic', 'pydantic', opts)
    end

    private

    # Some links lack the trailing slash, which would duplicate the pages
    def handle_response(response)
      response.url.path << '/' unless response.url.path.end_with?('/')
      super
    end
  end
end
