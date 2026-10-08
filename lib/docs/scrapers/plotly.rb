module Docs
  # The Python API reference (plotly.com/python-api-reference/, Sphinx) and
  # the Python guides (plotly.com/python/<guide>/, rendered notebooks) of
  # plotly 7.1.0. Neither site is versioned: both document the latest release.
  class Plotly < UrlScraper
    self.name = 'plotly'
    self.slug = 'plotly'
    self.type = 'sphinx'
    self.release = '7.1.0'
    self.base_url = 'https://plotly.com/'
    self.root_path = 'python-api-reference/index.html'
    self.links = {
      home: 'https://plotly.com/python/',
      code: 'https://github.com/plotly/plotly.py'
    }

    # The guides of the fundamentals and chart sections of plotly.com/python/,
    # by section. Left out: the migration guides, the Orca and Kaleido change
    # notes, and the AI/ML and Dash Bio sections (Dash applications).
    GUIDES = {
      'Fundamentals' => %w(getting-started figure-structure creating-and-updating-figures renderers plotly-express
                           static-image-export templates configuration-options setting-graph-size tick-formatting
                           figure-labels axes legend multiple-axes subplots graphing-multiple-chart-types px-arguments
                           marker-style colorscales text-and-annotations hover-text-and-formatting images shapes
                           ipython-vs-python troubleshooting builtin-colorscales discrete-color styling-plotly-express
                           interactive-html-export pandas-backend figure-factories wide-form graph-objects
                           figure-introspection horizontal-vertical-shapes selections css-colors),
      'Basic Charts' => %w(line-and-scatter line-charts bar-charts pie-charts bubble-charts dot-plots filled-area-plots
                           horizontal-bar-charts gantt sunburst-charts table sankey-diagram treemaps performance
                           figure-factory-table categorical-axes icicle-charts pattern-hatching-texture dumbbell-plots),
      'Statistical Charts' => %w(error-bars box-plots histograms distplot 2D-Histogram splom facet-plots
                                 parallel-categories-diagram tree-plots violin 2d-histogram-contour linear-fits
                                 marginal-plots strip-charts continuous-error-bars ecdf-plots),
      'Scientific Charts' => %w(contour-plots heatmaps imshow ternary-plots log-plot dendrogram annotated-heatmap
                                ternary-scatter-contour parallel-coordinates-plot quiver-plots streamline-plots
                                network-graphs carpet-plot carpet-contour carpet-scatter polar-chart radar-chart
                                ternary-contour wind-rose-charts smith-charts),
      'Financial Charts' => %w(time-series candlestick-charts waterfall-charts funnel-charts ohlc-charts indicator
                               gauge-charts bullet-charts),
      'Maps' => %w(mapbox-to-maplibre tile-county-choropleth lines-on-tile-maps filled-area-tile-maps bubble-maps
                   density-heatmaps lines-on-maps choropleth-maps tile-map-layers tile-scatter-maps
                   scatter-plots-on-maps map-configuration hexbin-map outline-map-locations),
      '3D Charts' => %w(3d-axes 3d-scatter-plots 3d-surface-plots 3d-subplots 3d-camera-controls 3d-bubble-charts
                        3d-line-plots trisurf 3d-mesh 3d-isosurface-plots 3d-volume-plots cone-plot streamtube-plot),
      'Subplots' => %w(mixed-subplots map-subplots-and-small-multiples table-subplots figure-factory-subplots)
    }
    GUIDE_PATHS = GUIDES.values.flatten.map { |guide| "python/#{guide}/" }

    self.initial_paths = GUIDE_PATHS

    html_filters.push 'plotly/entries', 'plotly/clean_html', 'sphinx/clean_html'

    options[:container] = ->(filter) { filter.slug.start_with?('python-api-reference') ? 'div[role="main"]' : 'main' }
    options[:only] = GUIDE_PATHS
    options[:only_patterns] = [/\Apython-api-reference\/(index|plotly\.[\w.]+|generated\/plotly\.[\w.]+)\.html\z/]
    options[:fix_urls] = ->(url) do
      # the guides link to themselves without the trailing slash
      url.sub(%r{\Ahttps://plotly\.com/python/([\w-]+)(?=\z|#)}, 'https://plotly.com/python/\1/')
    end
    options[:case_sensitive_paths] = true
    options[:max_image_size] = 300_000
    options[:rate_limit] = 300

    options[:attribution] = <<-HTML
      &copy; 2016&ndash;2026 Plotly Technologies Inc.<br>
      Licensed under the MIT License.
    HTML

    # The classes and functions that have a page of their own: the ones listed
    # in the summaries of the modules. The module pages document them too,
    # but only those pages are indexed.
    def self.dedicated_pages
      @dedicated_pages ||= %w(plotly.express plotly.graph_objects plotly.io plotly.figure_factory plotly.subplots).flat_map do |page|
        response = Request.run("https://plotly.com/python-api-reference/#{page}.html")
        raise "Couldn't get the #{page} summary: #{response.code}" unless response.success?
        response.body.scan(%r{href="generated/([\w.]+)\.html}).flatten
      end.to_set
    end

    def get_latest_version(opts)
      get_latest_github_release('plotly', 'plotly.py', opts)
    end
  end
end
