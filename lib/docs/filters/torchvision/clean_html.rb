module Docs
  class Torchvision
    class CleanHtmlFilter < Filter
      def call
        # "[source]" links into the highlighted module sources, which aren't scraped
        css('.viewcode-link').each { |node| (node.ancestors('a').first || node).remove }

        # sphinx-gallery: the example thumbnails (in the gallery indexes and
        # under "Examples using ...") become plain lists of links
        css('.sphx-glr-thumbnails').each do |node|
          links = node.css('.sphx-glr-thumbcontainer a').map { |link| "<li>#{link.to_html}</li>" }
          node.replace("<ul>#{links.join}</ul>")
        end
        css('.sphx-glr-thumbcontainer').each do |node|
          link = node.at_css('a')
          link ? node.replace("<p>#{link.to_html}</p>") : node.remove
        end

        # The tutorial cards of the PyTorch theme (filtered with JavaScript on
        # the site) become a list of the tutorials with their summaries
        css('#tutorial-cards-container').each do |node|
          items = node.css('.tutorials-card').map do |card|
            link = card.at_css('a')
            title = card.at_css('.card-title-container')&.content&.strip
            summary = card.at_css('.card-summary')&.inner_html
            next unless link && title
            "<dt><a href=\"#{link['href']}\">#{CGI.escapeHTML(title)}</a></dt><dd>#{summary}</dd>"
          end
          node.replace("<dl>#{items.compact.join}</dl>")
        end

        # The sound clips of the tutorials aren't part of the static pages
        css('audio').each do |node|
          container = node.ancestors('.output_subarea').first
          (container || node).remove
        end

        # Cloudflare-obfuscated e-mail links of the tutorial authors
        css('a[href*="cdn-cgi/l/email-protection"]').each do |node|
          node.before(node.children).remove
        end

        # "Try on Colab or go to the end to download the full example code"
        css('.admonition.note').each do |node|
          node.remove if node.content.include?('to download the full example code')
        end

        # download buttons, timing notes and rating widgets
        css('.sphx-glr-footer', '.sphx-glr-download', '.sphx-glr-download-link-note', '.sphx-glr-signature',
            '.sphx-glr-timing', '.pytorch-call-to-action-links', '.rating-container').remove

        # sphinx-gallery adds a srcset pointing to the original file, which
        # would take precedence over the embedded image
        css('img[srcset]').remove_attribute('srcset')

        # "highlight-Python" (sphinx-gallery) -> "highlight-python"
        css('div[class*="highlight-"]').each do |node|
          node['class'] = node['class'].sub(/highlight-([\w+]+)/) { "highlight-#{$1.downcase}" }
        end

        doc
      end
    end
  end
end
