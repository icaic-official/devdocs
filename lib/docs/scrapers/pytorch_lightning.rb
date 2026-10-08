module Docs
  # The docs on lightning.ai/docs/pytorch/ are now rendered by a JavaScript
  # application that only serves an empty shell to non-browser clients. The
  # same Sphinx build is still published unmodified on Read the Docs, which is
  # where this scraper takes it from.
  class PytorchLightning < UrlScraper
    self.name = 'PyTorch Lightning'
    self.slug = 'pytorch_lightning'
    self.type = 'sphinx'
    self.root_path = 'index.html'
    self.links = {
      home: 'https://lightning.ai/docs/pytorch/',
      code: 'https://github.com/Lightning-AI/pytorch-lightning'
    }

    html_filters.push 'pytorch_lightning/entries', 'pytorch/clean_html', 'torchvision/clean_html', 'pytorch_lightning/clean_html', 'sphinx/math', 'sphinx/clean_html'

    options[:skip] = %w(genindex.html search.html py-modindex.html tutorials.html past_versions.html)
    options[:skip_patterns] = [/\A_modules/, /\A_sources/, /\A_downloads/, /\Acommunity/, /\Agenerated\//, /\Anotebooks\//]
    options[:max_image_size] = 300_000
    options[:rate_limit] = 300

    options[:attribution] = <<-HTML
      &copy; Copyright (c) 2018&ndash;2026, Lightning AI et al.<br>
      Licensed under the Apache License, Version 2.0.
    HTML

    version '2.6' do
      self.release = '2.6.6'
      self.base_url = "https://pytorch-lightning.readthedocs.io/en/#{release}/pytorch/"
    end

    def get_latest_version(opts)
      get_latest_github_release('Lightning-AI', 'pytorch-lightning', opts)
    end
  end
end
