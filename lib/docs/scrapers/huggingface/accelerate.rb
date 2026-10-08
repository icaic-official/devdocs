module Docs
  class Accelerate < Huggingface
    self.name = 'Accelerate'
    self.slug = 'accelerate'
    self.links = {
      home: 'https://huggingface.co/docs/accelerate',
      code: 'https://github.com/huggingface/accelerate'
    }

    options[:attribution] = <<-HTML
      &copy; 2021&ndash;2026 The HuggingFace Team<br>
      Licensed under the Apache License, Version 2.0.
    HTML

    version '1.15' do
      self.release = '1.15.0'
      self.base_url = "https://huggingface.co/docs/accelerate/v1.15.0/en/"
      options[:github] = { repo: 'huggingface/accelerate', tag: 'v1.15.0', directory: 'docs/source' }
    end

    def get_latest_version(opts)
      get_latest_github_release('huggingface', 'accelerate', opts)
    end
  end
end
