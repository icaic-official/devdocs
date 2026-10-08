module Docs
  # Read the Docs has no release_3.4.0 build of the documentation: "stable"
  # is built from the release_3.4 branch (3.4.x).
  class Xgboost < UrlScraper
    self.name = 'XGBoost'
    self.slug = 'xgboost'
    self.type = 'sphinx'
    self.root_path = 'index.html'
    self.links = {
      home: 'https://xgboost.ai/',
      code: 'https://github.com/dmlc/xgboost'
    }

    html_filters.push 'xgboost/clean_html', 'xgboost/entries', 'sphinx/math', 'sphinx/clean_html'

    options[:container] = '.rst-content [itemprop="articleBody"]'
    # the general guides, the parameter reference and the Python package;
    # not the R, JVM, Julia and C packages, the contributor guide or the release notes
    options[:only] = %w(install.html get_started.html faq.html parameter.html prediction.html treemethod.html)
    options[:only_patterns] = [/\Atutorials\//, /\Agpu\//, /\Apython\//]
    options[:skip] = %w(tutorials/c_api_tutorial.html)
    options[:skip_patterns] = [/\A_modules/, /\A_sources/, /\A_downloads/, /\.(py|ipynb|txt|json|csv|zip)\z/]
    options[:max_image_size] = 300_000
    options[:rate_limit] = 300

    options[:attribution] = <<-HTML
      &copy; 2025, xgboost developers<br>
      Licensed under the Apache License, Version 2.0.
    HTML

    version '3.4' do
      self.release = '3.4'
      self.base_url = 'https://xgboost.readthedocs.io/en/stable/'
    end

    def get_latest_version(opts)
      get_latest_github_release('dmlc', 'xgboost', opts)
    end
  end
end
