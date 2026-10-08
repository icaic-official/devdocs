module Docs
  class Datasets < Huggingface
    self.name = 'Datasets'
    self.slug = 'datasets'
    self.links = {
      home: 'https://huggingface.co/docs/datasets',
      code: 'https://github.com/huggingface/datasets'
    }

    options[:attribution] = <<-HTML
      &copy; 2020&ndash;2026 The HuggingFace Team<br>
      Licensed under the Apache License, Version 2.0.
    HTML

    # huggingface.co doesn't serve the 5.0 docs (its version list stops at
    # 4.8.4), but hf-doc-build has built them all the same.
    version '5.0' do
      self.release = '5.0.1'
      self.base_url = "https://huggingface.co/docs/datasets/v5.0.1/en/"
      options[:github] = { repo: 'huggingface/datasets', tag: '5.0.1', directory: 'docs/source' }
    end

    def get_latest_version(opts)
      get_latest_github_release('huggingface', 'datasets', opts)
    end
  end
end
