module Docs
  class Trl < Huggingface
    self.name = 'TRL'
    self.slug = 'trl'
    self.links = {
      home: 'https://huggingface.co/docs/trl',
      code: 'https://github.com/huggingface/trl'
    }

    options[:skip] = %w(community_tutorials)
    options[:type_prefixes] = { 'Experimental' => 'Experimental' }

    options[:attribution] = <<-HTML
      &copy; 2020&ndash;2026 The HuggingFace Team<br>
      Licensed under the Apache License, Version 2.0.
    HTML

    version '1.13' do
      self.release = '1.13.0'
      self.base_url = "https://huggingface.co/docs/trl/v1.13.0/en/"
      options[:github] = { repo: 'huggingface/trl', tag: 'v1.13.0', directory: 'docs/source' }
    end

    def get_latest_version(opts)
      get_latest_github_release('huggingface', 'trl', opts)
    end
  end
end
