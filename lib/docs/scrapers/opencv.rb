module Docs
  # Built from the Doxygen HTML that OpenCV attaches to its GitHub releases:
  # docs.opencv.org serves the same pages behind a Cloudflare challenge. The
  # archive also documents the opencv_contrib modules and the C++, Java and
  # JavaScript tutorials; this keeps the main modules, which are the ones
  # opencv-python(-headless) ships, and the OpenCV-Python tutorials.
  class Opencv < FileScraper
    self.name = 'OpenCV'
    self.slug = 'opencv'
    self.type = 'simple'
    self.root_path = 'index.html'
    self.links = {
      home: 'https://opencv.org/',
      code: 'https://github.com/opencv/opencv'
    }

    html_filters.insert_before 'clean_local_urls', 'opencv/images'
    html_filters.push 'opencv/clean_html', 'opencv/math', 'opencv/entries'

    options[:container] = '#doc-content'
    options[:max_image_size] = 300_000

    options[:attribution] = <<-HTML
      &copy; 2000&ndash;2026 OpenCV team and contributors<br>
      Licensed under the Apache License, Version 2.0.
    HTML

    version '5.0' do
      self.release = '5.0.0'
    end

    # The modules listed as "Main modules" on the home page (geometry's groups
    # aren't nested under its empty page), each named after its module.
    MODULES = {
      'core' => 'core', 'imgproc' => 'imgproc', 'imgcodecs' => 'imgcodecs',
      'videoio' => 'videoio', 'highgui' => 'highgui', 'video' => 'video',
      'stereo' => 'stereo', 'features' => 'features', 'calib' => 'calib',
      'objdetect' => 'objdetect', 'dnn' => 'dnn', 'flann' => 'flann',
      'photo' => 'photo', 'ccm' => 'photo', 'stitching' => 'stitching',
      'd_projection' => 'geometry', 'geometry_shape' => 'geometry', '_3d' => 'geometry'
    }

    # C-level hardware acceleration interfaces, platform glue and C++-only
    # interoperability that the Python bindings don't expose, and the list of
    # the dnn layers' C++ classes
    SKIP_GROUPS = /hal|_sse\z|_neon\z|_vsx\z|directx|va_intel|lowlevel|_ios\z|macosx|winrt|\AdnnLayerList\z|\Acore_opencl\z|\Acore_eigen\z|softfloat|parallel_backend/

    TUTORIALS_ROOT = 'tutorial_py_root'
    INTRO = 'intro'

    def get_latest_version(opts)
      get_latest_github_release('opencv', 'opencv', opts)
    end

    def initial_paths
      pages.keys
    end

    private

    # Page path => [entry type, kind] for every page included, from the
    # Doxygen tag file.
    def pages
      @pages ||= begin
        assert_source_directory_exists
        tag = Nokogiri::XML(File.read(File.join(source_directory, 'opencv.tag')))
        compounds = tag.root.element_children.each_with_object({}) do |node, hash|
          name = node.at_xpath('name')&.content
          hash[[node['kind'], name]] = node if name
        end
        groups = compounds.select { |(kind, _), _| kind == 'group' }.transform_keys(&:last)
        page_nodes = compounds.select { |(kind, _), _| kind == 'page' }.values.index_by { |node| node.at_xpath('filename').content }
        result = {}

        add_tutorials = lambda do |node, type|
          path = node.at_xpath('filename').content
          next if result.key?(path)
          result[path] = [type, 'tutorial']
          node.xpath('subpage').each do |subpage|
            add_tutorials.call(page_nodes[subpage.content], type) if page_nodes[subpage.content]
          end
        end
        root = compounds[['page', TUTORIALS_ROOT]]
        result[root.at_xpath('filename').content] = ['Python Tutorials', 'tutorial']
        root.xpath('subpage').each do |subpage|
          node = page_nodes[subpage.content]
          add_tutorials.call(node, "Python Tutorials: #{node.at_xpath('title').content}")
        end

        intro = compounds[['page', INTRO]]
        result[intro.at_xpath('filename').content] = ['Introduction', 'intro']

        add_group = lambda do |name, mod|
          next if name =~ SKIP_GROUPS
          group = groups[name]
          result[group.at_xpath('filename').content] = [mod, 'group']
          group.xpath('class').each do |klass|
            node = compounds[['class', klass.content]] || compounds[['struct', klass.content]] || compounds[['union', klass.content]]
            next unless node
            result[node.at_xpath('filename').content] ||= [mod, 'class']
          end
          group.xpath('subgroup').each { |subgroup| add_group.call(subgroup.content, mod) }
        end
        MODULES.each { |name, mod| add_group.call(name, mod) }

        result
      end
    end

    def additional_options
      paths = Set.new(pages.keys)
      super.merge \
        only_patterns: [PageSet.new(paths)],
        opencv_pages: pages,
        source_directory: source_directory
    end

    # Matches the subpaths of the pages included: an `only` list of thousands
    # of paths would be scanned for every link.
    class PageSet
      def initialize(paths)
        @paths = paths
      end

      def =~(path)
        @paths.include?(path) ? 0 : nil
      end
    end

    # Nokogiri drops the whitespace-only lines and indentation of Doxygen's
    # code fragments (a <div> per line): they're turned into <pre> first, and
    # the tooltips Doxygen appends to them are removed.
    def parse(response)
      body = response.body.dup
      body.gsub!(%r{<div class="ttc"[^>]*>(?:<div class="tt\w+">.*?</div>)*</div>\n?}m, '')
      body.gsub!(%r{<div class="fragment">(.*?)</div><!-- fragment -->}m) do
        lines = $1.gsub(%r{<div class="line">(.*?)</div>\n?}m) { "#{$1}\n" }
        %(<pre class="fragment">#{lines.chomp}</pre>)
      end
      body.gsub!(%r{<div class="fragment">((?:<div class="line">.*?</div>\n?)*)</div>}m) do
        lines = $1.gsub(%r{<div class="line">(.*?)</div>\n?}m) { "#{$1}\n" }
        %(<pre class="fragment">#{lines.chomp}</pre>)
      end
      super(FileScraper::Response.new(body, response.url))
    end

    def download_source
      download_and_extract("https://github.com/opencv/opencv/releases/download/#{self.class.release}/opencv-#{self.class.release}-docs.zip", 'doc/doxygen/html')
    end
  end
end
