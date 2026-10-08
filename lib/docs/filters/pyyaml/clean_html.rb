module Docs
  class Pyyaml
    class CleanHtmlFilter < Filter
      def call
        css('style', 'script').remove

        # Pandoc's highlighted blocks: "<div class="sourceCode"><pre class="sourceCode python"><code><a class="sourceLine">"
        css('div.sourceCode').each do |node|
          pre = node.at_css('pre')
          lang = pre['class'].to_s[/sourceCode (\w+)/, 1] || 'python'
          new_pre = doc.document.create_element('pre', pre.content, 'data-language' => lang)
          new_pre['id'] = node['id'] if node['id']
          node.replace(new_pre)
        end

        css('pre:not([data-language])').each do |node|
          node.content = node.content
        end

        doc
      end
    end
  end
end
