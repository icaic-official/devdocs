module Docs
  class Xgboost
    class CleanHtmlFilter < Filter
      def call
        # [source] links to the _modules pages, which aren't scraped
        css('.viewcode-link').each { |node| (node.ancestors('a').first || node).remove }

        # "name : type" terms (the theme adds the colon with CSS)
        css('dt > .classifier').each { |node| node.before(' : ') }

        # sphinx-gallery: download links, timings and thumbnails
        css('.sphx-glr-footer', '.sphx-glr-download', '.sphx-glr-download-link-note', '.sphx-glr-signature',
            '.sphx-glr-timing').remove
        css('.sphx-glr-thumbnails').each do |node|
          links = node.css('.sphx-glr-thumbcontainer a').map { |link| "<li>#{link.to_html}</li>" }
          node.replace("<ul>#{links.join}</ul>")
        end
        css('.sphx-glr-thumbcontainer').each do |node|
          link = node.at_css('a')
          link ? node.replace("<p>#{link.to_html}</p>") : node.remove
        end
        css('img[srcset]').remove_attribute('srcset')

        # "highlight-Python" (sphinx-gallery) -> "highlight-python"
        css('div[class*="highlight-"]').each do |node|
          node['class'] = node['class'].sub(/highlight-([\w+]+)/) { "highlight-#{$1.downcase}" }
        end

        # Give each parameter of the parameter reference an anchor: the items
        # of the sections' lists starting with the name of the parameter (the
        # accepted values are listed in nested lists)
        if slug == 'parameter'
          ids = Hash.new(0)
          css('section > ul > li > p:first-child').each do |p|
            code = p.children.first
            next unless code&.name == 'code'
            name = code.content.strip
            id = "param-#{name}"
            id << "-#{ids[name] + 1}" if ids[name] > 0
            ids[name] += 1
            p.parent['id'] = id
          end
        end

        doc
      end
    end
  end
end
