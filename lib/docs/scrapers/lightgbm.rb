module Docs
  class Lightgbm < UrlScraper
    self.name = 'LightGBM'
    self.slug = 'lightgbm'
    self.type = 'sphinx'
    self.root_path = 'index.html'
    self.links = {
      home: 'https://lightgbm.readthedocs.io/',
      code: 'https://github.com/microsoft/LightGBM'
    }

    html_filters.push 'lightgbm/clean_html', 'lightgbm/entries', 'sphinx/math', 'sphinx/clean_html'

    options[:container] = '.rst-content [itemprop="articleBody"]'
    # the guides, the parameters and the Python API; not the C API, the R
    # package or the development guide
    options[:only] = %w(
      Installation-Guide.html Quick-Start.html Python-Intro.html Features.html Experiments.html
      Parameters.html Parameters-Tuning.html Python-API.html Parallel-Learning-Guide.html
      GPU-Tutorial.html GPU-Performance.html GPU-Targets.html Advanced-Topics.html FAQ.html
    )
    options[:only_patterns] = [/\Apythonapi\//]
    options[:skip_patterns] = [/\A_modules/, /\A_sources/, /\A_downloads/]
    options[:max_image_size] = 300_000
    options[:rate_limit] = 300

    options[:attribution] = <<-HTML
      &copy; Copyright Microsoft Corporation<br>
      Licensed under the MIT License.
    HTML

    version '4.7' do
      self.release = '4.7.0'
      self.base_url = "https://lightgbm.readthedocs.io/en/v#{release}/"
    end

    def get_latest_version(opts)
      get_latest_github_release('microsoft', 'LightGBM', opts)
    end
  end
end
