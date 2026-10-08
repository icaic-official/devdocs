require 'execjs'

module Docs
  class Opencv
    # Doxygen leaves the TeX of formulas between \( \) and \[ \] in the text
    # for MathJax: it's converted to MathML with KaTeX, like in Sphinx::MathFilter,
    # with the macros OpenCV's MathJax configuration defines.
    class MathFilter < Filter
      MACROS = {
        '\\matTT' => '\\left|\\begin{array}{ccc} #1 & #2 & #3\\\\ #4 & #5 & #6\\\\ #7 & #8 & #9 \\end{array}\\right|',
        '\\fork' => '\\left\\{ \\begin{array}{l l} #1 & \\mbox{#2}\\\\ #3 & \\mbox{#4}\\\\ \\end{array} \\right.',
        '\\forkthree' => '\\left\\{ \\begin{array}{l l} #1 & \\mbox{#2}\\\\ #3 & \\mbox{#4}\\\\ #5 & \\mbox{#6}\\\\ \\end{array} \\right.',
        '\\forkfour' => '\\left\\{ \\begin{array}{l l} #1 & \\mbox{#2}\\\\ #3 & \\mbox{#4}\\\\ #5 & \\mbox{#6}\\\\ #7 & \\mbox{#8}\\\\ \\end{array} \\right.',
        '\\vecthree' => '\\begin{bmatrix} #1\\\\ #2\\\\ #3 \\end{bmatrix}',
        '\\vecthreethree' => '\\begin{bmatrix} #1 & #2 & #3\\\\ #4 & #5 & #6\\\\ #7 & #8 & #9 \\end{bmatrix}',
        '\\cameramatrix' => '#1 = \\begin{bmatrix} f_x & 0 & c_x\\\\ 0 & f_y & c_y\\\\ 0 & 0 & 1 \\end{bmatrix}',
        '\\distcoeffs' => '(k_1, k_2, p_1, p_2[, k_3[, k_4, k_5, k_6 [, s_1, s_2, s_3, s_4[, \\tau_x, \\tau_y]]]]) \\text{ of 4, 5, 8, 12 or 14 elements}',
        '\\distcoeffsfisheye' => '(k_1, k_2, k_3, k_4)',
        '\\hdotsfor' => '\\dots',
        '\\mathbbm' => '\\mathbb{#1}',
        '\\bordermatrix' => '\\matrix{#1}'
      }

      RENDER_ALL = <<~JS
        function renderAll(items, macros) {
          return items.map(function(item) {
            return katex.renderToString(item[0], { displayMode: item[1], output: 'mathml', throwOnError: false, macros: Object.assign({}, macros) });
          });
        }
      JS

      FORMULA = /\\\((.+?)\\\)|\\\[(.+?)\\\]/m

      def self.context
        @context ||= ExecJS.compile("var exports, module, define;\n#{File.read(Sphinx::MathFilter::KATEX_PATH)}\n#{RENDER_ALL}")
      end

      def call
        nodes = xpath('.//text()[not(ancestor::pre) and not(ancestor::code) and (contains(., "\\(") or contains(., "\\["))]')
        parts = nodes.map { |node| split(node.content) }
        items = parts.flatten(1).select { |part| part.is_a?(Array) }
        return doc if items.empty?

        rendered = self.class.context.call('renderAll', items, MACROS)
        nodes.each_with_index do |node, index|
          html = parts[index].map do |part|
            if part.is_a?(Array)
              mathml = rendered.shift.delete_prefix('<span class="katex">').delete_suffix('</span>')
              %(<span class="math">#{mathml}</span>)
            else
              CGI.escapeHTML(part)
            end
          end
          node.replace(Nokogiri::HTML::DocumentFragment.new(doc.document, html.join))
        end

        doc
      end

      private

      # The text and [tex, display] pairs
      def split(text)
        parts = []
        position = 0
        text.scan(FORMULA) do
          match = Regexp.last_match
          parts << text[position...match.begin(0)] if match.begin(0) > position
          parts << (match[1] ? [match[1].strip, false] : [match[2].strip, true])
          position = match.end(0)
        end
        parts << text[position..] if position < text.length
        parts
      end
    end
  end
end
