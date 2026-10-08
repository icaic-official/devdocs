module Docs
  class Jupyterlab
    class CleanHtmlFilter < Filter
      def call
        # embedded YouTube videos become links
        css('iframe').each do |node|
          id = node['src'].to_s[%r{youtube(?:-nocookie)?\.com/embed/([\w-]+)}, 1]
          if id
            node.replace(%(<p><a href="https://www.youtube.com/watch?v=#{id}">Video: https://www.youtube.com/watch?v=#{id}</a></p>))
          else
            node.remove
          end
        end
        css('.video-container', 'div[style*="padding-bottom"]').each { |node| node.before(node.children).remove }

        css('img[srcset]').remove_attribute('srcset')
        css('img').remove_attribute('width').remove_attribute('height')

        # the User Guide's table of contents, which the home page already lists
        css('a[href="user/index"]').each { |node| node.before(node.children).remove } if root_page?

        doc
      end
    end
  end
end
