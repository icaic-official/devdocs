module Docs
  class Seaborn
    class EntriesFilter < Docs::EntriesFilter
      # The sections of the function interface in the API reference (api.html)
      FUNCTION_TYPES = {
        'Relational plots' => %w(relplot scatterplot lineplot),
        'Distribution plots' => %w(displot histplot kdeplot ecdfplot rugplot distplot),
        'Categorical plots' => %w(catplot stripplot swarmplot boxplot violinplot boxenplot pointplot barplot countplot),
        'Regression plots' => %w(lmplot regplot residplot),
        'Matrix plots' => %w(heatmap clustermap),
        'Multi-plot grids' => %w(FacetGrid pairplot PairGrid jointplot JointGrid),
        'Themeing' => %w(set_theme axes_style set_style plotting_context set_context set_color_codes reset_defaults reset_orig set),
        'Color palettes' => %w(set_palette color_palette husl_palette hls_palette cubehelix_palette dark_palette light_palette
                               diverging_palette blend_palette xkcd_palette crayon_palette mpl_palette
                               choose_colorbrewer_palette choose_cubehelix_palette choose_light_palette
                               choose_dark_palette choose_diverging_palette),
        'Utility functions' => %w(despine move_legend saturate desaturate set_hls_values load_dataset get_dataset_names get_data_home)
      }.each_with_object({}) { |(type, names), hash| names.each { |name| hash[name] = type } }

      def get_name
        return 'API reference' if slug == 'api'
        name = at_css('h1').content.delete('#¶').strip
        name << '()' if function_page?
        name
      end

      def get_type
        if slug.start_with?('generated/seaborn.objects.')
          'Objects interface'
        elsif slug.start_with?('generated/')
          FUNCTION_TYPES[slug.split('.')[1]] || 'API'
        elsif slug.start_with?('tutorial')
          'Tutorial'
        else
          'Guides'
        end
      end

      def include_default_entry?
        !root_page?
      end

      # Attributes and methods documented on the class pages themselves (most
      # methods have their own page)
      def additional_entries
        return [] unless slug.start_with?('generated/')
        page_id = slug.sub('generated/', '')
        css('dl.py > dt[id]').each_with_object([]) do |node, entries|
          next if node['id'] == page_id || node['id'].end_with?('.__init__')
          kind = node.parent['class'][/\bpy (\w+)/, 1]
          name = node['id'].dup
          name << '()' if %w(function method classmethod staticmethod).include?(kind)
          entries << [name, node['id']]
        end
      end

      private

      def function_page?
        dl = at_css('dl.py')
        dl && dl['class'][/\bpy (\w+)/, 1].in?(%w(function method classmethod staticmethod))
      end
    end
  end
end
