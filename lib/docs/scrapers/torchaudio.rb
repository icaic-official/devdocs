module Docs
  class Torchaudio < UrlScraper
    self.name = 'torchaudio'
    self.slug = 'torchaudio'
    self.type = 'sphinx'
    self.root_path = 'index.html'
    self.links = {
      home: 'https://docs.pytorch.org/audio/',
      code: 'https://github.com/pytorch/audio'
    }

    html_filters.push 'torchvision/entries', 'pytorch/clean_html', 'torchvision/clean_html', 'sphinx/math', 'sphinx/clean_html'

    options[:skip] = %w(genindex.html search.html py-modindex.html logo.html)
    options[:skip_patterns] = [/\A_modules/, /\A_sources/, /\A_downloads/]
    options[:max_image_size] = 300_000
    options[:rate_limit] = 300

    options[:attribution] = <<-HTML
      &copy; Copyright 2026, Torchaudio Contributors<br>
      Licensed under the BSD 2-Clause License.
    HTML

    version '2.11' do
      self.release = '2.11'
      self.base_url = "https://docs.pytorch.org/audio/#{release}/"
    end

    def get_latest_version(opts)
      get_latest_github_release('pytorch', 'audio', opts)
    end
  end
end
