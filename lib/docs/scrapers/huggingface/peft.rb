module Docs
  class Peft < Huggingface
    self.name = 'PEFT'
    self.slug = 'peft'
    self.links = {
      home: 'https://huggingface.co/docs/peft',
      code: 'https://github.com/huggingface/peft'
    }

    options[:skip] = %w(developer_guides/contributing)

    options[:attribution] = <<-HTML
      &copy; 2023&ndash;2026 The HuggingFace Team<br>
      Licensed under the Apache License, Version 2.0.
    HTML

    version '0.21' do
      self.release = '0.21.0'
      self.base_url = "https://huggingface.co/docs/peft/v0.21.0/en/"
      options[:github] = { repo: 'huggingface/peft', tag: 'v0.21.0', directory: 'docs/source' }
    end

    def get_latest_version(opts)
      get_latest_github_release('huggingface', 'peft', opts)
    end
  end
end
