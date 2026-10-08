module Docs
  class Plotly
    class CleanHtmlFilter < Filter
      def call
        guide? ? clean_guide : clean_reference
        doc
      end

      private

      def guide?
        slug.start_with?('python/')
      end

      def clean_reference
        css('.viewcode-link').each { |node| (node.ancestors('a').first || node).remove }
        css('dt > .classifier').each { |node| node.before(' : ') }
      end

      # The guides are rendered notebooks: the title is in the page header and
      # the cells in section.tutorial-content
      def clean_guide
        title = at_css('header h1')&.content&.squish
        content = at_css('section.tutorial-content')
        doc.inner_html = "<h1>#{CGI.escapeHTML(title.to_s)}</h1>"
        doc << content.children

        # the "What About Dash?" and "… in Dash" cells (Dash apps embedded
        # from another site) and the Dash newsletter sign-up
        css('h2, h3, h4').each do |node|
          next unless node.content =~ /\AWhat About Dash\?|\bin Dash\b/
          (node.ancestors('.cell').first || node).remove
        end
        css('iframe').each { |node| (node.ancestors('.cell').first || node).remove }
        css('.cell').each { |node| node.remove if node.content.include?('Sign up for Dash Club') }

        # Interactive figures (Plotly.js embeds) and widgets can't be shown;
        # static images, text and HTML table outputs stay
        css('.output_area').each do |node|
          if node.at_css('script, .plotly-graph-div, .output_widget_view, .output_javascript')
            node.remove
          end
        end
        css('.output_area').each do |node|
          if (text = node.at_css('.output_text pre'))
            text['class'] = 'plotly-output'
          end
        end
        css('script', 'style', '.prompt', '.anchor-link').remove

        # code cells: "<div class="highlight hl-ipython3"><pre>"
        css('.input_area .highlight', '.text_cell_render .highlight').each do |node|
          pre = node.at_css('pre')
          pre.content = pre.content.strip
          pre['data-language'] = 'python'
          node.replace(pre)
        end
        css('pre:not([data-language])').each { |node| node.content = node.content.strip }

        css('.cell', '.inner_cell', '.input', '.input_area', '.text_cell_render', '.output_wrapper', '.output',
            '.output_area', '.output_subarea').each do |node|
          node.before(node.children).remove
        end

        # headings are named after their text: "Line-Plots-with-plotly.express"
        css('h2, h3, h4').each { |node| node.content = node.content.strip }
      end
    end
  end
end
