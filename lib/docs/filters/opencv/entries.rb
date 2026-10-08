module Docs
  class Opencv
    class EntriesFilter < Docs::EntriesFilter
      MODULES = {
        'core' => 'core: Core Functionality',
        'imgproc' => 'imgproc: Image Processing',
        'imgcodecs' => 'imgcodecs: Image File Reading and Writing',
        'videoio' => 'videoio: Video I/O',
        'highgui' => 'highgui: High-level GUI',
        'video' => 'video: Video Analysis',
        'stereo' => 'stereo: Stereo Correspondence',
        'features' => 'features: Feature Detection and Matching',
        'calib' => 'calib: Camera Calibration',
        'objdetect' => 'objdetect: Object Detection',
        'dnn' => 'dnn: Deep Neural Networks',
        'flann' => 'flann: Nearest Neighbor Search',
        'photo' => 'photo: Computational Photography',
        'stitching' => 'stitching: Image Stitching',
        'geometry' => 'geometry: Computational Geometry'
      }

      def page
        @page ||= context[:opencv_pages][subpath] || []
      end

      def kind
        page.last
      end

      def get_name
        title = at_css('h1').content.strip
        return title unless kind == 'class'
        name = title.sub(/ (Class|Struct|Union)( Template)? Reference\z/, '').gsub(/<\s+/, '<').gsub(/\s+>/, '>').strip
        python? ? name.gsub('::', '.') : name
      end

      def get_type
        MODULES[page.first] || page.first
      end

      # the functions and methods that have Python bindings, by their Python names
      def additional_entries
        return [] if root_page? || %w(group class).exclude?(kind)
        names = Set.new([name])
        css('h3[id]').each_with_object([]) do |node, entries|
          signature = node.next_element
          while signature && signature['class'] == 'python-signature'
            python_name = signature.content[/\A[\w.]+(?=\()/]
            entries << [python_name, node['id']] if python_name && names.add?(python_name)
            signature = signature.next_element
          end
        end
      end

      private

      def python?
        at_css('pre.python-signature').present?
      end
    end
  end
end
