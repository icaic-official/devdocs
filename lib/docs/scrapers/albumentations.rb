module Docs
  # albumentations.ai now documents AlbumentationsX, the successor of the
  # albumentations package, and the sources of the old site aren't public. The
  # API reference of the last albumentations release is generated from its
  # docstrings by albumentations/api_reference.py, and the home page from its
  # README. The guides on albumentations.ai describe AlbumentationsX's API
  # (which differs from 2.0's in places), so they aren't included.
  class Albumentations < FileScraper
    self.name = 'Albumentations'
    self.slug = 'albumentations'
    self.type = 'simple'
    self.root_path = 'index.html'
    self.links = {
      home: 'https://albumentations.ai/',
      code: 'https://github.com/albumentations-team/albumentations'
    }

    html_filters.push 'albumentations/clean_html', 'albumentations/entries'

    options[:attribution] = <<-HTML
      &copy; 2017 Vladimir Iglovikov, Alexander Buslaev, Alexander Parinov and contributors<br>
      Licensed under the MIT License.
    HTML

    version '2.0' do
      self.release = '2.0.8'
    end

    REPOSITORY = 'https://github.com/albumentations-team/albumentations.git'
    API_REFERENCE = File.expand_path('albumentations/api_reference.py', __dir__)

    # The parts of the README kept on the home page
    README_SECTIONS = ['Installation', 'A simple example', 'List of augmentations']

    def get_latest_version(opts)
      get_latest_github_release('albumentations-team', 'albumentations', opts)
    end

    def initial_paths
      assert_source_directory_exists
      Dir.glob('**/*.html', base: source_directory).sort
    end

    private

    def download_source
      require 'tmpdir'

      Dir.mktmpdir do |directory|
        repository = File.join(directory, 'albumentations')
        output = File.join(directory, 'html')

        instrument 'info.doc', msg: %(Cloning albumentations #{self.class.release}...)
        system('git', '-c', 'advice.detachedHead=false', 'clone', '--quiet', '--depth', '1', '--branch', self.class.release, REPOSITORY, repository, exception: true)

        instrument 'info.doc', msg: 'Generating the API reference from the docstrings...'
        system('python3', API_REFERENCE, repository, output, exception: true)

        names = JSON.parse(File.read(File.join(output, 'names.json')))
        index = File.join(output, 'index.html')
        readme = render_readme(File.read(File.join(repository, 'README.md')), names)
        File.write(index, File.read(index).sub('<!-- README -->') { readme })

        FileUtils.mkpath(File.dirname(source_directory))
        FileUtils.mv(output, source_directory)
      end
    end

    def render_readme(markdown, names)
      sections = markdown.split(/^(?=## )/)
      intro = sections.shift.lines.reject do |line|
        # the title, badges, banners, links and the sentence introducing an image
        line =~ /\A(# |\[!\[|!\[|> |\[Docs\]|Here is an example)/
      end
      kept = sections.select { |section| README_SECTIONS.include?(section[/\A## (.+)/, 1].strip) }
      markdown = ([intro.join] + kept).join("\n")
      # the documentation of the transforms instead of their demos
      markdown.gsub!(%r{https://explore\.albumentations\.ai/transform/(\w+)}) { names[$1] || $& }
      markdown.gsub!(/^Other installation options are described in .*$/, '')

      html = Kramdown::Document.new(markdown, input: 'GFM', hard_wrap: false, syntax_highlighter: nil).to_html
      intro_end = html.index('<h2') || html.length
      html.insert(intro_end, <<~HTML)
        <p>This documentation covers albumentations #{self.class.release}, the last release of the MIT-licensed
        <code>albumentations</code> package. Its API reference is generated from the package&#8217;s docstrings.
        <a href="https://albumentations.ai/">albumentations.ai</a> now documents its successor, AlbumentationsX.</p>
      HTML
      html
    end
  end
end
