module Docs
  class Jupyterlab < UrlScraper
    self.name = 'JupyterLab'
    self.slug = 'jupyterlab'
    self.type = 'sphinx'
    self.root_path = 'index.html'
    self.links = {
      home: 'https://jupyter.org/',
      code: 'https://github.com/jupyterlab/jupyterlab'
    }

    html_filters.push 'jupyterlab/entries', 'jupyterlab/clean_html', 'sphinx/clean_html'

    options[:container] = 'article.bd-article'
    # Getting Started, the User Guide and the extension development guides.
    # Left out: the changelog, the contributor guide (developer/*), the
    # privacy policies, and the TypeScript API reference (api/*, linked from
    # developer/api.html), thousands of generated TypeDoc pages for the
    # JavaScript packages that the extension guides only point to.
    options[:only] = %w(index.html)
    options[:only_patterns] = [/\Agetting_started\//, /\Auser\//, /\Aextension\//]
    options[:skip] = %w(getting_started/changelog.html)
    # the animated screenshots of the table of contents and the debugger
    options[:max_image_size] = 2_500_000
    options[:rate_limit] = 300

    options[:attribution] = <<-HTML
      &copy; 2015&ndash;2026 Project Jupyter Contributors<br>
      Licensed under the 3-clause BSD License.
    HTML

    version '4.6' do
      self.release = '4.6.4'
      self.base_url = 'https://jupyterlab.readthedocs.io/en/4.6.x/'
    end

    def get_latest_version(opts)
      get_latest_github_release('jupyterlab', 'jupyterlab', opts)
    end
  end
end
