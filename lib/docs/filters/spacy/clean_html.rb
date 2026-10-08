module Docs
  class Spacy
    class CleanHtmlFilter < Filter
      def call
        # header: the title, its tags ("class", "v3.0") and teaser; not the
        # "Source" button
        if header = at_css('header[class*="title_root"]')
          title = header.at_css('h1')
          title.content = title.content.strip
          title.remove_attribute('id')
          tags = header.css('[class*="tag_root"]').map { |tag| tag_html(tag) }.join(' ')
          teaser = header.at_css('.heading-teaser')
          html = title.to_html
          html << %(<p class="_spacy-tags">#{tags}</p>) if tags.present?
          html << %(<p class="_spacy-teaser">#{teaser.inner_html}</p>) if teaser
          header.replace(html)
        end

        # "Suggest edits" and "Read next"
        css('a[class*="readnext_root"]').each { |node| node.parent.remove }
        css('a[href*="github.com/explosion/spaCy/tree/"][class*="button_root"]').each do |node|
          (node.ancestors('[class*="grid_root"]').first || node).remove
        end

        # interactive widgets
        css('[class*="quickstart_root"]').each do |node|
          node = node.parent if node.parent['id'] == 'quickstart'
          node.replace(%(<p class="_note">The interactive quickstart widget is available on <a href="#{current_url}">spacy.io</a>.</p>))
        end
        css('iframe').each do |node|
          src = node['src'].to_s
          src.include?('youtube') ? node.replace(%(<p><a href="#{src}">#{node['title'].presence || 'Video'} (YouTube)</a></p>)) : node.remove
        end

        # "$ command" fields
        css('[class*="copy_root"]').each do |node|
          node.replace(%(<pre data-language="bash">#{CGI.escapeHTML(node.at_css('textarea').content.strip)}</pre>))
        end

        # accordions: a heading (in the button) with its content
        css('section.accordion').each do |node|
          title = node.at_css('button .heading-text')
          content = node.at_css('[class*="accordion_content"]')
          node.inner_html = %(<h4 id="#{node['id']}">#{title.inner_html.strip}</h4>#{content.inner_html})
          node.name = 'div'
          node.remove_attribute('id')
        end

        # headings: the text of the permalinks, then the tags ("method", "v3.0")
        css('h2, h3, h4, h5, h6').each do |node|
          tags = node.css('[class*="tag_root"]').map { |tag| tag_html(tag) }
          node.css('[class*="tag_root"]').remove
          text = node.at_css('.heading-text')
          node.inner_html = text.inner_html if text
          node.inner_html = "#{node.inner_html.strip} #{tags.join(' ')}".strip
        end
        css('[class*="tag_root"]').each { |tag| tag.replace(tag_html(tag)) }

        # info boxes and the examples that the site shows beside the text
        css('aside[class*="infobox_root"]').each do |node|
          node.name = 'div'
          node['class'] = node['class'].include?('infobox_warning') || node['class'].include?('infobox_danger') ? '_note _note-red' : '_note'
          if title = node.at_css('[class*="infobox_title"]')
            title.css('[class*="infobox_emoji"]').remove
            title.replace(%(<p><strong>#{title.text.strip.gsub(/\s+/, ' ')}</strong></p>)) unless title.text.blank?
          end
        end
        css('aside[class*="aside_root"]').each do |node|
          node.replace(%(<div class="_spacy-aside">#{node.at_css('[class*="aside_text"]').inner_html}</div>))
        end

        # images: no placeholders or srcset
        css('img').each do |node|
          node.remove_attribute('srcset')
          node.remove_attribute('srcSet')
          node.remove_attribute('loading')
          node.remove_attribute('decoding')
          node.remove_attribute('height') if node['height'] == 'auto'
          node['src'] = URI.join(base_url.to_s, CGI.unescape(node['src'][/url=([^&]+)/, 1])).to_s if node['src'].to_s.include?('/.netlify/images?')
        end

        # the integration cards' titles are logos
        css('[class*="card_title"]').each { |node| node.remove if node.text.blank? }

        css('.type-annotation').each do |node|
          node.name = 'code'
          node['class'] = '_spacy-type'
          node.remove_attribute('aria-label')
        end

        css('svg[aria-hidden]', 'button').remove
        css('section').each { |node| node.before(node.children).remove }

        css('*[class]').each do |node|
          classes = node['class'].split.select { |name| name.start_with?('_') }
          classes.empty? ? node.remove_attribute('class') : node['class'] = classes.join(' ')
        end
        css('[role]').remove_attribute('role')

        # badges without an image (the site's "Made with love and spaCy" one);
        # the Markdown that follows them shows them anyway
        css('img[src="#"]').remove

        doc
      end

      private

      # "v3.0" tags have the version split into several text nodes
      def tag_html(node)
        %(<span class="_spacy-tag">#{CGI.escapeHTML(node.text.strip)}</span>)
      end
    end
  end
end
