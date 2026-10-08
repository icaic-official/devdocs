module Docs
  class Catboost
    class EntriesFilter < Docs::EntriesFilter
      # slug prefixes of the Python reference pages and the object they document
      # (the longest prefixes first)
      PYTHON_OBJECTS = [
        ['concepts/python-reference_catboostclassifier', 'CatBoostClassifier'],
        ['concepts/python-reference_catboostregressor', 'CatBoostRegressor'],
        ['concepts/python-reference_catboostranker', 'CatBoostRanker'],
        ['concepts/python-reference_catboostipythonwidget', 'MetricVisualizer'],
        ['concepts/python-reference_virtual_ensemblesranker', 'CatBoostRanker'],
        ['concepts/python-reference_virtual_ensembles', 'CatBoost'],
        ['concepts/python-reference_catboost', 'CatBoost'],
        ['concepts/python-reference_save_quantization_borders', 'Pool'],
        ['concepts/python-reference_pool', 'Pool'],
        ['concepts/python-data-processing', 'Pool'],
        ['concepts/python-reference_tokenizer', 'Tokenizer'],
        ['concepts/python-reference_dictionary', 'Dictionary'],
        ['concepts/python-reference_utils', 'catboost.utils'],
        ['concepts/python-reference_datasets', 'catboost.datasets'],
        ['concepts/python-features-data', 'FeaturesData']
      ]

      APPLY_MODEL = 'concepts/python-reference_apply_catboost_model'

      GROUPS = [
        [%r{\A(concepts/installation|concepts/python-installation|installation/)}, 'Installation'],
        [%r{\Areferences/training-parameters}, 'Training parameters'],
        [%r{\Aconcepts/loss-functions}, 'Objectives and metrics'],
        [%r{\Aconcepts/(model-analysis|fstr|shap-values|feature-analysis-graph|feature-interaction|ostr)}, 'Model analysis'],
        [%r{\Aconcepts/input-data}, 'Input data'],
        [%r{\Aconcepts/output-data}, 'Output data'],
        [%r{\Aconcepts/algorithm-|\Aconcepts/quantization}, 'Algorithm details'],
        [%r{\Afeatures/visualization}, 'Visualization'],
        [%r{\Afeatures/}, 'Features'],
        [%r{\Aconcepts/python-}, 'Python package']
      ]

      def get_name
        title = at_css('h1').content.strip
        if (object = python_object)
          return object if title == 'Overview' || title == object.split('.').last
          return "#{object} #{title.downcase}" if title == 'Attributes'
          return title if title.include?(' ')
          return "#{object}.#{title}#{'()' if callable?}"
        end
        return 'Applying a model in Python' if slug == APPLY_MODEL
        return "catboost.#{title}()" if python_function?
        return "#{type}: Overview" if title == 'Overview'
        # the build guides for each platform share their title
        return "#{title} (#{$1 == 'windows' ? 'Windows' : 'Linux and macOS'})" if slug =~ /build-from-source-(windows|linux-macos)\z/
        title
      end

      def get_type
        return "Python: #{python_object}" if python_object
        return 'Python package' if slug == APPLY_MODEL
        return 'Python: functions' if python_function?
        GROUPS.each { |pattern, group| return group if slug =~ pattern }
        'Guides'
      end

      # The training parameters, but not the ones only the command-line
      # version has ("--learn-pairs"), and the metrics
      def additional_entries
        if slug.start_with?('references/training-parameters/') && slug != 'references/training-parameters/'
          css('h2[id]').map { |node| [node.content.strip, node['id']] }.reject { |name, _| name.start_with?('-') }
        elsif slug.start_with?('concepts/loss-functions-') && slug != 'concepts/loss-functions-variables-used'
          css('h3[id]').map { |node| ["#{node.content.strip} (#{name.split(':').first} metric)", node['id']] }
        else
          []
        end
      end

      private

      # methods and functions have a "Method call format" section
      def callable?
        css('h2').any? { |node| node.content.strip =~ /call format\z/i }
      end

      def python_match
        @python_match ||= PYTHON_OBJECTS.find { |prefix, _| slug == prefix || slug.start_with?("#{prefix}_") }
      end

      def python_object
        python_match&.last
      end

      # cv, train, sum_models, to_classifier, ...
      def python_function?
        slug.start_with?('concepts/python-reference_') && !python_object
      end
    end
  end
end
