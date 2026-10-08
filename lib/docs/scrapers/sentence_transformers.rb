module Docs
  # sbert.net only serves the documentation of the latest release, 6.1.0, a
  # documentation refresh over 6.0.1 that leaves the API unchanged.
  class SentenceTransformers < UrlScraper
    self.name = 'Sentence Transformers'
    self.slug = 'sentence_transformers'
    self.type = 'sphinx'
    self.root_path = 'index.html'
    self.links = {
      home: 'https://sbert.net/',
      code: 'https://github.com/huggingface/sentence-transformers'
    }

    html_filters.push 'sentence_transformers/entries', 'sentence_transformers/clean_html', 'sphinx/math', 'sphinx/clean_html'

    options[:container] = '.rst-content [itemprop="articleBody"]'
    # the guides, the API reference and the training examples' READMEs
    options[:only_patterns] = [/\Adocs\//, /\Aexamples\//]
    options[:skip] = %w(genindex.html search.html py-modindex.html docs/publications.html)
    options[:skip_patterns] = [
      /\A_modules/, /\A_sources/, /\A_static/, /\.(py|ipynb|txt|json|csv)\z/,
      # old URLs that redirect to the API pages, which would otherwise be stored twice
      %r{\Adocs/package_reference/(sentence_transformer/SentenceTransformer|sparse_encoder/SparseEncoder|cross_encoder/cross_encoder|quantization)\.html\z}i
    ]
    options[:max_image_size] = 300_000
    options[:rate_limit] = 300

    options[:attribution] = <<-HTML
      &copy; 2019&ndash;2026 Nils Reimers, Tom Aarsen and the Sentence Transformers contributors<br>
      Licensed under the Apache License, Version 2.0.
    HTML

    version '6.1' do
      self.release = '6.1.0'
      self.base_url = 'https://sbert.net/'
    end

    def get_latest_version(opts)
      get_latest_github_release('huggingface', 'sentence-transformers', opts)
    end
  end
end
