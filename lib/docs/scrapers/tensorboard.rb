module Docs
  # TensorBoard has no API reference site of its own: its documentation is the
  # README of the repository (concepts, dashboards, command line usage and the
  # FAQ), scraped at the release tag, and the TensorBoard guides published on
  # tensorflow.org/tensorboard, which are generated from the docs/ folder of the
  # same repository. Only those guides are scraped; the TensorFlow API pages
  # they link to stay external links, and the TensorFlow 1.x guides (docs/r1)
  # and internal design documents are left out. The PyTorch writer for
  # TensorBoard logs, torch.utils.tensorboard, is documented with PyTorch.
  class Tensorboard < UrlScraper
    include MultipleBaseUrls

    self.name = 'TensorBoard'
    self.slug = 'tensorboard'
    self.type = 'simple'
    self.root_path = 'README.md'
    self.links = {
      home: 'https://www.tensorflow.org/tensorboard',
      code: 'https://github.com/tensorflow/tensorboard'
    }

    GUIDES = %w(
      get_started tensorboard_in_notebooks scalars_and_keras image_summaries graphs
      hyperparameter_tuning_with_hparams text_summaries tensorboard_projector_plugin
      what_if_tool tensorboard_profiling_keras debugger_v2 dataframe_api migrate
    )

    html_filters.push 'tensorboard/clean_html', 'tensorboard/entries'

    options[:only] = GUIDES.dup
    # the dashboard screenshots are the point of most guides
    options[:max_image_size] = 1_500_000
    options[:rate_limit] = 30

    options[:attribution] = <<-HTML
      &copy; 2017&ndash;2026 The TensorFlow Authors. All rights reserved.<br>
      Code licensed under the Apache License, Version 2.0. Guides licensed under the Creative Commons Attribution License 4.0.
    HTML

    version '2.21' do
      self.release = '2.21.0'
      self.base_urls = [
        "https://github.com/tensorflow/tensorboard/blob/#{release}/",
        'https://www.tensorflow.org/tensorboard/'
      ]
    end

    def initial_urls
      [root_url.to_s, *GUIDES.map { |guide| "https://www.tensorflow.org/tensorboard/#{guide}" }]
    end

    def get_latest_version(opts)
      get_latest_github_release('tensorflow', 'tensorboard', opts)
    end
  end
end
