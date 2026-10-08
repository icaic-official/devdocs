module Docs
  class Transformers < Huggingface
    self.name = 'Transformers'
    self.slug = 'transformers'
    self.links = {
      home: 'https://huggingface.co/docs/transformers',
      code: 'https://github.com/huggingface/transformers'
    }

    # contributor guides, the Hub's community pages and the notebook links
    options[:skip] = %w(contributing pr_checks testing community notebooks models_timeline)
    options[:type_prefixes] = { 'model_doc/' => 'Models', 'internal/' => 'Internal helpers' }

    options[:attribution] = <<-HTML
      &copy; 2018&ndash;2026 The HuggingFace Team<br>
      Licensed under the Apache License, Version 2.0.
    HTML

    version '5.17' do
      self.release = '5.17.0'
      self.base_url = "https://huggingface.co/docs/transformers/v5.17.0/en/"
      options[:github] = { repo: 'huggingface/transformers', tag: 'v5.17.0', directory: 'docs/source/en' }
    end

    def get_latest_version(opts)
      get_latest_github_release('huggingface', 'transformers', opts)
    end
  end
end
