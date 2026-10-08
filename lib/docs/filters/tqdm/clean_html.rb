module Docs
  class Tqdm
    class CleanHtmlFilter < Filter
      def call
        root_page? ? clean_readme : clean_module
        css('.headerlink').remove

        css('div.highlight').each do |node|
          pre = node.at_css('pre')
          pre.content = pre.content.chomp
          pre['data-language'] = 'python'
          node.replace(pre)
        end

        doc
      end

      private

      # The README rendered by GitHub
      def clean_readme
        # Keep the screenshots only: not the logo, the status badges, the
        # contributor chart and the video, slides and merch banners
        css('img').each do |node|
          src = node['data-canonical-src'] || node['src']
          keep = src =~ %r{\Ahttps://tqdm\.github\.io/img/(tqdm|jupyter-\d|screenshot-[\w-]+)\.(gif|png)\z}
          if keep
            node['src'] = src
            %w(data-canonical-src data-animated-image style).each { |attr| node.remove_attribute(attr) }
            link = node.ancestors('a').first
            link.replace(node) if link
          else
            link = node.ancestors('a').first
            block = node.ancestors('p, li').first
            # badges standing for a word in a sentence ("GitHub's Releases: [badge]") become their text
            if node['alt'].present? && block && block.content.strip.present?
              node.replace(CGI.escapeHTML(node['alt']))
            else
              (link || node).remove
            end
          end
        end
        css('p, div[align]').each { |node| node.remove if node.content.strip.empty? && !node.at_css('img') }

        # "<div class="markdown-heading"><h2>…</h2><a class="anchor" id="user-content-…">"
        css('.markdown-heading').each do |node|
          heading = node.at_css('h1, h2, h3, h4, h5, h6')
          anchor = node.at_css('a.anchor')
          heading['id'] = anchor['id'].sub(/\Auser-content-/, '') if anchor
          node.replace(heading)
        end
        css('a[href^="#user-content-"]').each { |node| node['href'] = node['href'].sub('#user-content-', '#') }
        css('[id^="user-content-"]').each { |node| node['id'] = node['id'].sub(/\Auser-content-/, '') }
        css('svg', '.zeroclipboard-container').remove

        css('.highlight > pre').each do |node|
          node.content = node.content.chomp
          node['data-language'] = node.parent['class'][/highlight-source-(\w+)/, 1] || 'python'
          node['data-language'] = 'bash' if node['data-language'] == 'shell'
          node.parent.replace(node)
        end
        css('pre:not([data-language])').each { |node| node.content = node.content }

        # The title is an h2 and the sections are h3 and h4
        at_css('h2')&.tap { |node| node.name = 'h1' }
        css('markdown-accessiblity-table').each { |node| node.before(node.children).remove }
        css('#table-of-contents').remove
        css('h1, h2, h3, h4, h5, h6').css('> a[href="#table-of-contents"]').each do |node|
          node.before(node.children).remove
        end
        # the sponsor logos
        css('p:has(> strong)').each do |node|
          next unless node.content.strip == 'Featured Sponsors'
          node.next_element.remove if node.next_element&.name == 'table'
          node.remove
        end
      end

      # The API pages generated with pydoc-markdown: "<p><a id="tqdm.std.tqdm.update"></a></p> <h4 id="update">"
      def clean_module
        css('p > a[id]:only-child').each do |node|
          heading = node.parent.next_element
          next unless heading && heading.name =~ /\Ah\d\z/
          heading['id'] = node['id']
          node.parent.remove
        end

        # "[view source]" links to the sources on GitHub
        css('span[style*="float: right"]').each do |node|
          (node.parent.name == 'p' && node.parent.content.strip == node.content.strip ? node.parent : node).remove
        end
      end
    end
  end
end
