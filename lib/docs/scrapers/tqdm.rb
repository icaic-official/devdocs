module Docs
  # tqdm.github.io documents the API of the latest release (4.70.1) module by
  # module; its home page is a shortened copy of the README, so the full
  # README (installation, usage, parameters, FAQ and examples) is taken from
  # the v4.70.1 tag instead, rendered by the GitHub API.
  class Tqdm < UrlScraper
    self.name = 'tqdm'
    self.slug = 'tqdm'
    self.type = 'simple'
    self.release = '4.70.1'
    self.base_url = 'https://tqdm.github.io/'
    self.root_path = '/'
    # the home page doesn't link to the module pages outside of its navigation
    self.initial_paths = %w(tqdm asyncio cli contrib contrib.concurrent contrib.discord contrib.itertools
                            contrib.logging contrib.slack contrib.telegram dask gui keras notebook rich
                            shortcuts tk tqdm.utils).map { |name| "docs/#{name}/" } + %w(dev/warnings/)
    self.links = {
      home: 'https://tqdm.github.io/',
      code: 'https://github.com/tqdm/tqdm'
    }

    README_URL = 'https://api.github.com/repos/tqdm/tqdm/readme?ref=v4.70.1'

    html_filters.push 'tqdm/clean_html', 'tqdm/entries'

    options[:container] = 'article.md-content__inner'
    # the README and the API reference; not the release notes, the
    # contributing guide, the internal monitor thread, the video and the merch
    options[:only] = %w(/ dev/warnings/)
    options[:only_patterns] = [/\Adocs\/[\w.]+\/\z/]
    # the animated screenshots of the README and the Telegram module (1.3 MB)
    options[:max_image_size] = 1_500_000
    options[:rate_limit] = 300

    options[:attribution] = <<-HTML
      &copy; 2015&ndash;2026 tqdm developers<br>
      Licensed under the MPL-2.0 and MIT Licenses.
    HTML

    def get_latest_version(opts)
      get_latest_github_release('tqdm', 'tqdm', opts)
    end

    private

    def parse(response)
      return super unless response.effective_url.to_s == root_url.to_s
      readme = Request.run(README_URL, headers: { 'Accept' => 'application/vnd.github.html', 'User-Agent' => 'DevDocs' })
      raise "Couldn't get the tqdm README: #{readme.code}" unless readme.success?
      ["<article class=\"md-content__inner tqdm-readme\">#{readme.body}</article>", 'tqdm']
    end
  end
end
