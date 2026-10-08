module Docs
  class Torchvision < UrlScraper
    self.name = 'torchvision'
    self.slug = 'torchvision'
    self.type = 'sphinx'
    self.root_path = 'index.html'
    self.links = {
      home: 'https://docs.pytorch.org/vision/',
      code: 'https://github.com/pytorch/vision'
    }

    html_filters.push 'torchvision/entries', 'pytorch/clean_html', 'torchvision/clean_html', 'sphinx/math', 'sphinx/clean_html'

    options[:skip] = %w(genindex.html search.html py-modindex.html)
    options[:skip_patterns] = [/\A_modules/, /\A_sources/, /\A_downloads/]
    options[:max_image_size] = 300_000
    options[:rate_limit] = 300

    options[:attribution] = <<-HTML
      &copy; Copyright 2017&ndash;present, Torch Contributors<br>
      Licensed under the BSD 3-Clause License.
    HTML

    version '0.29' do
      self.release = '0.29'
      self.base_url = "https://docs.pytorch.org/vision/#{release}/"
    end

    def get_latest_version(opts)
      get_latest_github_release('pytorch', 'vision', opts)
    end
  end
end
