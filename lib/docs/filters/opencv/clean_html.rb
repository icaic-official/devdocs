module Docs
  class Opencv
    class CleanHtmlFilter < Filter
      # groups titled after their names
      TITLES = {
        'group____3d' => '3D Point Cloud Segmentation',
        'group__geometry__shape' => '2D Shapes',
        'group__geometry__subdiv2d' => 'Planar Subdivision'
      }

      def call
        title = at_css('.headertitle .title')
        title.css('.ingroups', '.mlabels').remove if title
        title = TITLES[File.basename(subpath, '.html')] || title&.content&.strip

        # the headings of the tutorials start at <h1>
        if %w(tutorial intro).include?(context[:opencv_pages][subpath]&.last) && at_css('.contents h1')
          css('.contents h5, .contents h4, .contents h3, .contents h2, .contents h1').each do |node|
            node.name = "h#{node.name[1].to_i + 1}"
          end
        end

        css('.header', 'script', '#MSearchSelectWindow', '#MSearchResultsWindow', 'hr.footer', 'address.footer',
            '.permalink', '.dynheader', '.dyncontent', 'iframe', 'object', 'tr[class^="separator"]',
            'a[href="#details"]', '.memtemplate').remove
        # the C++ headers
        css('p > code:only-child').each { |node| node.parent.remove if node.content.start_with?('#include') }

        root_page? ? clean_home_page : doc.children.first.before("<h1>#{CGI.escapeHTML(title.to_s)}</h1>")

        clean_members
        clean_anchors

        css('tr.heading').each do |node|
          heading = node.at_css('h2')
          table = node.ancestors('table').first
          table.before(heading) if heading
          node.remove
        end

        css('pre.fragment').each do |node|
          node.content = node.content.rstrip
          node['data-language'] = python?(node.content) ? 'python' : 'cpp'
          node.remove_attribute('class')
        end

        css('.python_language').each do |node|
          node.replace(%(<br><code>#{CGI.escapeHTML(node.content.delete_prefix('Python:').strip)}</code>))
        end

        css('div.image', 'div.caption', '.textblock', '.contents', 'div:not([class]):not([id])').each do |node|
          node.before(node.children).remove
        end
        css('div.caption').remove

        css('a').each { |node| node.remove if node.content.strip == 'More...' }
        css('h2.groupheader', 'a.el', 'tr[class]').each { |node| node.remove_attribute('class') }
        css('[style]').each { |node| node.remove_attribute('style') }
        css('td[valign], td[align]').each do |node|
          node.remove_attribute('valign')
          node.remove_attribute('align')
        end

        doc
      end

      private

      def clean_home_page
        at_css('.title')&.remove
        doc.children.first.before('<h1>OpenCV 5.0</h1>')
        css('li').each do |node|
          text = node.children.first
          node.remove if text&.text? && text.content.start_with?('Extra modules')
        end
        # the pages that aren't included are no longer links
        css('li').each { |node| node.remove if node.at_css('a[href], ul').nil? }
        if main = css('li').find { |node| node.children.first&.text? && node.children.first.content.start_with?('Main modules') }
          links = context[:opencv_pages].select { |_, (mod, kind)| mod == 'geometry' && kind == 'group' }.keys.map do |path|
            name = File.basename(path, '.html')
            %(<a href="#{path.downcase.delete_suffix('.html')}">#{TITLES[name] || '3D Vision Functionality'}</a>)
          end
          main.at_css('ul').add_child("<li>geometry. #{links.join(', ')}</li>")
        end
      end

      # Doxygen's tables of a function's return type, name, parameter types
      # and names become a C++ signature, and the table of its Python
      # signatures a Python one; the titles become headings.
      def clean_members
        css('h2.memtitle').each do |node|
          node.name = 'h3'
          node.remove_attribute('class')
          anchor = node.previous_element
          if anchor && anchor.name == 'a' && anchor['id']
            node['id'] = anchor['id']
            anchor.remove
          end
          node.css('.overload').each { |overload| overload.content = " #{overload.content.strip}" }
        end

        css('.memproto').each do |node|
          html = +''
          node.css('table.python_language tr').each do |row|
            next if row.at_css('th')
            signature = row.css('td').map(&:content).join.gsub(/[[:space:]]+/, ' ').strip
            html << %(<pre data-language="python" class="python-signature">#{CGI.escapeHTML(signature)}</pre>) if signature.present?
          end
          if table = node.at_css('table.memname')
            html << %(<pre data-language="cpp">#{CGI.escapeHTML(cpp_signature(table))}</pre>)
          end
          node.replace(html)
        end

        css('.memitem', '.memdoc').each { |node| node.before(node.children).remove }
      end

      def cpp_signature(table)
        lines = []
        table.css('tr').each do |row|
          text = row.css('td').map(&:content).join(' ').gsub(/[[:space:]]+/, ' ').strip
          next if text.empty?
          if lines.empty? || text.start_with?(')')
            lines << '' if lines.empty?
            lines[-1] = "#{lines[-1]} #{text}".strip
          else
            lines << text
          end
        end
        lines.map! { |line| line.gsub(/<\s+/, '<').gsub(/\s+>/, '>').gsub(/\s+([,)])/, '\1') }
        first = lines.first.sub(/\s*\(\s*/, '(')
        indent = ' ' * ((first.index('(') || -1) + 1)
        ([first] + lines.drop(1).map { |line| indent + line }).join("\n")
      end

      # Doxygen's empty anchors would be removed with the other empty
      # elements: their ids go to the elements they're for.
      def clean_anchors
        css('a[id]:not([href])').each do |node|
          next unless node.content.strip.empty?
          target = node.parent if %w(h1 h2 h3 h4 h5 h6 td th dt li).include?(node.parent.name)
          target ||= node.next_element
          target ||= node.parent.next_element if node.parent.content.strip.empty?
          target['id'] ||= node['id'] if target
          node.remove
        end
        css('a[name]').each { |node| node.remove_attribute('name') }
      end

      def python?(code)
        subpath.include?('tutorial_py_') || code =~ /^\s*(import|from)\s+\w|^\s*def\s+\w+\(.*\):|\bcv\.\w+\(|\bnp\.\w/
      end
    end
  end
end
