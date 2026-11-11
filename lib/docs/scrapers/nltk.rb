module Docs
  # www.nltk.org only serves the documentation of 3.9.2, so the documentation of
  # the 3.10 release is built from its sources (see docs/file-scrapers.md).
  class Nltk < FileScraper
    self.name = 'NLTK'
    self.slug = 'nltk'
    self.type = 'sphinx'
    self.release = '3.10.4'
    self.root_path = 'index.html'
    # the home page doesn't link to the other pages outside of its navigation
    self.initial_paths = %w(install.html data.html howto.html api/nltk.html)
    self.links = {
      home: 'https://www.nltk.org/',
      code: 'https://github.com/nltk/nltk'
    }

    html_filters.insert_before 'clean_local_urls', 'local_images'
    html_filters.push 'nltk/clean_html', 'nltk/entries', 'sphinx/math', 'sphinx/clean_html'

    options[:container] = '#main-content'
    # the API reference and the HOWTOs; not the release notes, the team and
    # contribution pages or the NLTK book (a separate site)
    options[:only] = %w(index.html install.html data.html howto.html)
    options[:only_patterns] = [/\Aapi\/nltk[\w.]*\.html\z/, /\Ahowto\/[\w-]+\.html\z/]
    options[:skip_patterns] = [/\A_modules/, /\A_sources/]

    options[:attribution] = <<-HTML
      &copy; 2001&ndash;2026 NLTK Project<br>
      Licensed under the Apache License, Version 2.0.
    HTML

    def get_latest_version(opts)
      get_latest_github_release('nltk', 'nltk', opts)
    end
  end
end
