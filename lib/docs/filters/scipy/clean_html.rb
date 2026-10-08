module Docs
  class Scipy
    class CleanHtmlFilter < Filter
      def call
        # the "Try it in your browser!" JupyterLite buttons and their iframes
        css('.try_examples_button_container', '.try_examples_outer_iframe', '.jupyterlite_sphinx_iframe_container').remove
        css('.try_examples_outer_container', '.try_examples_content').each { |node| node.before(node.children).remove }
        css('.viewcode-link', '.headerlink').remove

        # "minimize" headed by a separate "scipy.optimize." prefix
        if (prename = at_css('.prename')) && (h1 = at_css('h1'))
          h1.inner_html = "#{prename.content.strip}#{h1.content.strip}"
          prename.remove
        end
        css('div.empty').remove

        # the cards on the home page become headings and paragraphs
        css('.sd-card').each do |node|
          header = node.at_css('.sd-card-header')&.content&.strip
          body = node.at_css('.sd-card-body')
          link = node.at_css('.sd-card-footer a')
          html = +''
          html << (link ? %(<h2><a href="#{link['href']}">#{header}</a></h2>) : "<h2>#{header}</h2>")
          html << body.css('p').map { |p| "<p>#{p.inner_html}</p>" }.join if body
          node.replace(html)
        end
        css('.sd-col', '.sd-row', '.sd-container-fluid').each { |node| node.before(node.children).remove }

        # notebook output: plain text, not code
        css('div.output.highlight-myst-ansi', 'div.output[class*="highlight-"]').each do |node|
          pre = node.at_css('pre')
          next node.remove unless pre
          pre.content = pre.content
          pre['class'] = 'output'
          node.replace(pre)
        end

        # sphinx/clean_html flattens parameter names and types into one <code>
        css('dt > .classifier').each { |node| node.before(' : ') }

        css('.pst-scrollable-table-container').each { |node| node.before(node.children).remove }

        doc
      end
    end
  end
end
