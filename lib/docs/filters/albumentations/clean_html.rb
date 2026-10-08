module Docs
  class Albumentations
    class CleanHtmlFilter < Filter
      def call
        # the README's illustrations are external images
        css('img').remove

        css('pre > code').each do |node|
          pre = node.parent
          language = node['class'].to_s[/language-(\w+)/, 1]
          pre['data-language'] = language == 'py' ? 'python' : language if language
          pre.content = node.content.chomp
        end

        doc
      end
    end
  end
end
