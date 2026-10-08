require 'execjs'

module Docs
  class Sphinx
    # Sphinx leaves the TeX of math roles and directives for MathJax to render
    # in the browser, which DevDocs doesn't load. This converts it to MathML
    # with KaTeX (lib/docs/vendor/katex) when scraping instead, in one Node process per
    # page.
    class MathFilter < Filter
      KATEX_PATH = File.expand_path('../../vendor/katex/katex.min.js', __dir__)

      RENDER_ALL = <<~JS
        function renderAll(items) {
          return items.map(function(item) {
            return katex.renderToString(item[0], { displayMode: item[1], output: 'mathml', throwOnError: false });
          });
        }
      JS

      def self.context
        # hide the CommonJS globals so that the UMD bundle defines `katex`
        @context ||= ExecJS.compile("var exports, module, define;\n#{File.read(KATEX_PATH)}\n#{RENDER_ALL}")
      end

      def call
        nodes = css('.math').select { |node| node.content.strip.present? }
        return doc if nodes.empty?

        items = nodes.map { |node| tex_of(node) }
        self.class.context.call('renderAll', items).each_with_index do |mathml, index|
          nodes[index].inner_html = mathml.delete_prefix('<span class="katex">').delete_suffix('</span>')
        end

        doc
      end

      private

      def tex_of(node)
        tex = node.content.strip
        if tex.start_with?('\\(') && tex.end_with?('\\)')
          [tex[2..-3], false]
        elsif tex.start_with?('\\[') && tex.end_with?('\\]')
          [tex[2..-3], true]
        else
          [tex, node.name == 'div']
        end
      end
    end
  end
end
