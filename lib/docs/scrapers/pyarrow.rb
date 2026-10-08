module Docs
  # arrow.apache.org publishes the docs of the current release (25.0.x) at
  # /docs/ only; /docs/<version>/ holds the older ones.
  class Pyarrow < UrlScraper
    self.name = 'PyArrow'
    self.slug = 'pyarrow'
    self.type = 'sphinx'
    self.root_path = 'index.html'
    self.links = {
      home: 'https://arrow.apache.org/docs/python/',
      code: 'https://github.com/apache/arrow'
    }

    # the entries are typed after the sidebar, which pyarrow/clean_html removes
    html_filters.push 'pyarrow/entries', 'pyarrow/clean_html', 'sphinx/math', 'sphinx/clean_html'

    options[:container] = nil
    options[:skip] = %w(genindex.html search.html py-modindex.html getting_involved.html)
    options[:skip_patterns] = [/\A_modules/, /\A_sources/, /\A_downloads/, /\A_static/]
    # pyarrow.Table and pyarrow.table, pyarrow.Schema and pyarrow.schema, ...
    options[:case_sensitive_paths] = true
    options[:max_image_size] = 300_000
    options[:rate_limit] = 300

    options[:attribution] = <<-HTML
      &copy; 2016&ndash;2026 Apache Software Foundation<br>
      Licensed under the Apache License, Version 2.0.
    HTML

    version '25.0' do
      self.release = '25.0.1'
      self.base_url = 'https://arrow.apache.org/docs/python/'
    end

    def get_latest_version(opts)
      get_latest_github_release('apache', 'arrow', opts).delete_prefix('apache-arrow-')
    end
  end
end
