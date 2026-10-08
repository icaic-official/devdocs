module Docs
  class Scipy
    class EntriesFilter < Docs::EntriesFilter
      def get_name
        if api_page?
          name = api_name.dup
          name << '()' if callable?
          name
        elsif module_page?
          "scipy.#{slug.split('/').last}"
        else
          at_css('h1').content.strip.delete_suffix('#').strip
        end
      end

      def get_type
        if api_page?
          module_of(api_name.delete_prefix('scipy.'))
        elsif module_page?
          name = slug.split('/').last
          if name.include?('-') || name.end_with?('_api', 'migration_to_sparray') || name.start_with?('stats._')
            module_of(name)
          else
            "scipy.#{name}"
          end
        elsif slug.start_with?('tutorial/stats/')
          'User Guide: Statistics'
        elsif slug.start_with?('tutorial/interpolate/')
          'User Guide: Interpolation'
        elsif slug.start_with?('tutorial/')
          'User Guide'
        else
          'API Reference'
        end
      end

      def include_default_entry?
        !root_page?
      end

      private

      # the object the page documents ("czt-function" documents scipy.signal.czt)
      def api_name
        @api_name ||= begin
          dt = at_css('dl[class] > dt[id^="scipy."]')
          dt ? dt['id'] : slug.split('/').last.delete_suffix('-class')
        end
      end

      def api_page?
        slug.start_with?('reference/generated/')
      end

      def module_page?
        slug.start_with?('reference/') && !api_page? && !%w(reference/index reference/main_namespace).include?(slug)
      end

      def callable?
        dl = at_css('dl.py, dl[class*="function"]')
        dl && (dl['class'].include?('function') || dl['class'].include?('method'))
      end

      MODULES = %w(
        cluster cluster.hierarchy cluster.vq constants datasets differentiate fft fftpack
        integrate interpolate io io.matlab linalg linalg.blas linalg.cython_blas
        linalg.cython_lapack linalg.interpolative linalg.lapack ndimage odr optimize
        optimize.cython_optimize optimize.elementwise signal signal.windows sparse
        sparse.csgraph sparse.linalg spatial spatial.distance spatial.transform special
        special.cython_special stats stats.contingency stats.mstats stats.qmc stats.sampling
      ).to_set

      # The longest documented module ("sparse.linalg", "stats.qmc", ...)
      # the object belongs to.
      def module_of(name)
        parts = name.split(/[.\-]/)
        parts.length.downto(1) do |n|
          candidate = parts.first(n).join('.')
          return "scipy.#{candidate}" if MODULES.include?(candidate)
        end
        'scipy'
      end
    end
  end
end
