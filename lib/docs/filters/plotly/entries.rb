module Docs
  class Plotly
    class EntriesFilter < Docs::EntriesFilter
      GUIDE_TYPES = Docs::Plotly::GUIDES.each_with_object({}) do |(type, guides), hash|
        guides.each { |guide| hash[guide] = "Guides: #{type}" }
      end

      def get_name
        if guide?
          at_css('header h1').content.squish.sub(/ in Python\z/, '')
        else
          name = at_css('h1').content.delete('¶#').strip.sub(/ ?[:—–].*\z/, '').sub(/ (package|module)\z/, '')
          # the summaries of the modules, whose own pages have the same names
          name << ' (summary)' unless slug.include?('/generated/')
          name << '()' if function_page?
          name
        end
      end

      def get_type
        if guide?
          GUIDE_TYPES[slug.split('/')[1]] || 'Guides'
        else
          # plotly.graph_objects.Scatter, plotly.express.line
          name[/\A[\w.]+/].split('.').first(2).join('.')
        end
      end

      def include_default_entry?
        !root_page?
      end

      # The classes, methods and properties documented on the reference
      # pages. Each is indexed on one page only: a class page indexes its own
      # members (its nested classes are documented by the module of the same
      # name), and a module page leaves out the members that have a page of
      # their own.
      def additional_entries
        return [] if guide?
        css('dl.py.class > dt[id], dl.py.method > dt[id], dl.py.function > dt[id]').each_with_object([]) do |node, entries|
          id = node['id']
          next if id == page_id || id.end_with?('.__init__')
          next unless own_entry?(id)
          kind = node.parent['class'][/\bpy (\w+)/, 1]
          kind = 'property' if kind == 'method' && node.content.strip.start_with?('property ')
          entries << [%w(method function).include?(kind) ? "#{id}()" : id, id]
        end
      end

      private

      def guide?
        slug.start_with?('python/')
      end

      def page_id
        slug.split('/').last.delete_suffix('.html')
      end

      def own_entry?(id)
        if page_id.split('.').last =~ /\A[A-Z]/
          id.start_with?("#{page_id}.")
        elsif !id.start_with?("#{page_id}.")
          true
        else
          child = id.delete_prefix("#{page_id}.").split('.').first
          !Docs::Plotly.dedicated_pages.include?("#{page_id}.#{child}")
        end
      end

      def function_page?
        slug.include?('/generated/') && css('dl.py.function > dt[id]').any? { |node| node['id'] == page_id }
      end
    end
  end
end
