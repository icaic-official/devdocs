require 'yaml'

module Docs
  # Base scraper for the Hugging Face libraries documented with doc-builder
  # (https://github.com/huggingface/doc-builder): Transformers, Accelerate,
  # PEFT, TRL, Datasets and Evaluate.
  #
  # huggingface.co/docs serves the pages of each version from a zip archive of
  # server-side rendered HTML published in the hf-doc-build/doc-build dataset,
  # which is scraped instead of the website. The pages are the ones listed in the
  # archive's table of contents (_toctree.yml), less the sections a scraper
  # leaves out in options[:skip_sections] (contribution guides, community pages).
  #
  # The rendered pages only hold the first option of the tabbed blocks
  # (<hfoptions>, e.g. "Pipeline | AutoModel | CLI"), whose other options are
  # left for the browser to render. Those are taken from the Markdown sources of
  # the release in the GitHub repository (see Huggingface::TabsFilter).
  #
  # A subclass sets the base URL of a version, which is that of the website:
  #   https://huggingface.co/docs/<doc>/v<release>/en/
  # and options[:github] to the repository, tag and directory of the sources.
  class Huggingface < FileScraper
    self.abstract = true
    self.type = 'huggingface'
    self.root_path = 'index'

    html_filters.insert_before 'apply_base_url', 'huggingface/tabs'
    html_filters.push 'huggingface/clean_html', 'huggingface/entries'

    options[:skip_sections] = []
    options[:max_image_size] = 300_000

    DOC_BUILD_URL = 'https://huggingface.co/datasets/hf-doc-build/doc-build/resolve/main'

    def mdx_directory
      File.join(source_directory, '_source')
    end

    private

    # Every page of the table of contents, not only those linked from others.
    def initial_paths
      toctree.keys - [root_path]
    end

    def additional_options
      { only: toctree.keys, toctree: toctree, package: package, anchors: anchors, mdx_directory: mdx_directory }
    end

    # "transformers/v5.17.0/en", the directory of the version in the archive
    def archive_directory
      base_url.path.delete_prefix('/docs/').delete_suffix('/')
    end

    def package
      archive_directory.split('/').first
    end

    def download_source
      download_and_extract("#{DOC_BUILD_URL}/#{archive_directory.delete_suffix('/en')}.zip", archive_directory)

      github = self.class.options[:github]
      archive = "https://codeload.github.com/#{github[:repo]}/tar.gz/refs/tags/#{github[:tag]}"
      directory = "#{github[:repo].split('/').last}-#{github[:tag].delete_prefix('v')}/#{github[:directory]}"
      download_and_extract(archive, directory, destination: mdx_directory)
    end

    # The pages of the table of contents, by path, with the titles of the
    # sections they're in.
    def toctree
      @toctree ||= {}.tap do |pages|
        assert_source_directory_exists
        walk = lambda do |items, sections|
          items.each do |item|
            next if self.class.options[:skip_sections].include?(item['title'])
            if item['sections']
              walk.call(item['sections'], sections + [item['title'].to_s.strip])
            elsif item['local'] && !item['local'].include?('://')
              pages[item['local'].delete_suffix('.html')] ||= sections
            end
          end
        end
        walk.call(YAML.load_file(File.join(source_directory, '_toctree.yml')), [])
        self.class.options[:skip].to_a.each { |path| pages.delete(path) }
      end
    end

    # The pages documenting each object (the ids of the docstrings), which the
    # links of the Markdown sources ([`Trainer`]) point to.
    def anchors
      @anchors ||= {}.tap do |anchors|
        prefix = Regexp.escape(package)
        toctree.each_key do |page|
          file = File.join(source_directory, "#{page}.html")
          next unless File.exist?(file)
          File.read(file).scan(/<span class="group flex space-x-1\.5 items-center[^"]*" id="(#{prefix}\.[\w.]+)"/) do |(id)|
            anchors[id] ||= page
          end
        end
      end
    end

    # The pages are linked without the extension of their files.
    def read_file(path)
      super(File.extname(path).empty? ? "#{path}.html" : path)
    end
  end
end
