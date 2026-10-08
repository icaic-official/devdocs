module Docs
  class Evaluate < Huggingface
    self.name = 'Evaluate'
    self.slug = 'evaluate'
    self.links = {
      home: 'https://huggingface.co/docs/evaluate',
      code: 'https://github.com/huggingface/evaluate'
    }

    options[:attribution] = <<-HTML
      &copy; 2022&ndash;2026 The HuggingFace Team<br>
      Licensed under the Apache License, Version 2.0.
    HTML

    version '0.4' do
      self.release = '0.4.6'
      self.base_url = "https://huggingface.co/docs/evaluate/v0.4.6/en/"
      options[:github] = { repo: 'huggingface/evaluate', tag: 'v0.4.6', directory: 'docs/source' }
    end

    def get_latest_version(opts)
      get_latest_github_release('huggingface', 'evaluate', opts)
    end
  end
end
