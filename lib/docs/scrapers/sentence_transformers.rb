module Docs
  # sbert.net only serves the documentation of the latest release, so the
  # documentation of the 6.0 release is built from its sources (see
  # docs/file-scrapers.md).
  class SentenceTransformers < FileScraper
    self.name = 'Sentence Transformers'
    self.slug = 'sentence_transformers'
    self.type = 'sphinx'
    self.root_path = 'index.html'
    self.links = {
      home: 'https://sbert.net/',
      code: 'https://github.com/huggingface/sentence-transformers'
    }

    html_filters.insert_before 'clean_local_urls', 'local_images'
    html_filters.push 'sentence_transformers/entries', 'sentence_transformers/clean_html', 'sphinx/math', 'sphinx/clean_html'

    options[:container] = '.rst-content [itemprop="articleBody"]'
    # the guides, the API reference and the training examples' READMEs
    options[:only_patterns] = [/\Adocs\//, /\Aexamples\//]
    options[:skip] = %w(genindex.html search.html py-modindex.html docs/publications.html)
    options[:skip_patterns] = [
      /\A_modules/, /\A_sources/, /\A_static/, /\.(py|ipynb|txt|json|csv)\z/
    ]
    # Old URLs that sbert.net redirects to the pages that replaced them; the
    # build has no page at those URLs, but the docs still link to them
    REDIRECTS = {
      'util' => 'util/index',
      'quantization' => 'util/quantization',
      'sentence_transformer/SentenceTransformer' => 'sentence_transformer/model',
      'sparse_encoder/SparseEncoder' => 'sparse_encoder/model',
      'cross_encoder/cross_encoder' => 'cross_encoder/model'
    }
    options[:fix_urls] = ->(url) do
      url.sub(%r{/docs/package_reference/(#{REDIRECTS.keys.join('|')})\.html(?=\z|#)}) do
        "/docs/package_reference/#{REDIRECTS[$1]}.html"
      end
    end
    options[:max_image_size] = 300_000

    options[:attribution] = <<-HTML
      &copy; 2019&ndash;2026 Nils Reimers, Tom Aarsen and the Sentence Transformers contributors<br>
      Licensed under the Apache License, Version 2.0.
    HTML

    version '6.0' do
      self.release = '6.0.1'
    end

    def get_latest_version(opts)
      get_latest_github_release('huggingface', 'sentence-transformers', opts)
    end
  end
end
