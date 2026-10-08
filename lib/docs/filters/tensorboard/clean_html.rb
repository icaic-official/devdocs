module Docs
  class Tensorboard
    class CleanHtmlFilter < Filter
      def call
        root_page? ? clean_readme : clean_guide
        doc
      end

      def clean_readme
        @doc = at_css('article.markdown-body')

        # GitHub puts the anchors next to the headings and resolves them with JavaScript
        css('.markdown-heading').each do |node|
          heading = node.at_css('h1, h2, h3, h4, h5, h6')
          anchor = node.at_css('a.anchor')
          heading['id'] = anchor['href'].delete_prefix('#') if anchor && anchor['href']
          heading.remove_attribute('class')
          heading.remove_attribute('tabindex')
          heading.remove_attribute('dir')
          node.replace(heading)
        end

        # CI and PyPI badges
        at_css('h1').css('a').remove
        at_css('h1').content = at_css('h1').content.strip

        css('.highlight').each do |node|
          pre = node.at_css('pre')
          pre['data-language'] = node['class'][/highlight-source-(\w+)/, 1] == 'shell' ? 'bash' : 'python'
          pre.content = pre.content
          pre.remove_attribute('class')
          node.replace(pre)
        end

        css('.snippet-clipboard-content').each do |node|
          pre = node.at_css('pre')
          pre.content = pre.content
          pre.remove_attribute('class')
          node.replace(pre)
        end

        css('a[id^="user-content-"]:empty').remove
        css('[dir]').remove_attribute('dir')
      end

      def clean_guide
        title = at_css('h1.devsite-page-title').children.select(&:text?).map(&:content).join.strip
        @doc = at_css('.devsite-article-body')

        css('.tfo-notebook-buttons', 'devsite-thumb-rating', '.devsite-floating-action-buttons',
            'div[itemscope]', 'devsite-bookmark', 'devsite-feedback', 'button').remove

        doc.children.first.before("<h1>#{CGI.escapeHTML(title)}</h1>")

        css('devsite-code').each do |node|
          node.before(node.children).remove
        end

        css('pre').each do |node|
          output = node.ancestors('.tfo-notebook-code-cell-output').any? || node['class'].to_s.include?('tfo-notebook-code-cell-output')
          # the notebook outputs escape colons twice ("https&amp;colon;//")
          node.content = node.content.gsub('&colon;', ':')
          node.remove_attribute('class')
          node['data-language'] = 'python' unless output
        end

        css('aside.note', 'aside.caution', 'aside.warning').each do |node|
          node.name = 'blockquote'
        end

        css('div:empty', 'p:empty').remove

        %w(translate dir tabindex data-text is-upgraded syntax syntax-guessed).each do |attribute|
          css("[#{attribute}]").remove_attribute(attribute)
        end
      end
    end
  end
end
