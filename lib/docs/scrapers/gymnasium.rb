module Docs
  # gymnasium.farama.org keeps each release's documentation under /v<release>/
  # (a Sphinx "dirhtml" build, so every page is a directory).
  class Gymnasium < UrlScraper
    self.name = 'Gymnasium'
    self.slug = 'gymnasium'
    self.type = 'sphinx'
    self.root_path = ''
    # Most pages are only linked from the navigation, which isn't scraped: the
    # pages of its introduction, API, environments and tutorials sections.
    self.initial_paths = %w(
      introduction/basic_usage/ introduction/train_agent/ introduction/create_custom_env/
      introduction/record_agent/ introduction/speed_up_env/ introduction/migration_guide/
      api/env/ api/registry/ api/spaces/ api/spaces/fundamental/ api/spaces/composite/ api/spaces/utils/
      api/wrappers/ api/wrappers/table/ api/wrappers/misc_wrappers/ api/wrappers/action_wrappers/
      api/wrappers/observation_wrappers/ api/wrappers/reward_wrappers/
      api/vector/ api/vector/wrappers/ api/vector/async_vector_env/ api/vector/sync_vector_env/ api/vector/utils/
      api/utils/ api/functional/ api/typing/
      environments/classic_control/ environments/classic_control/acrobot/ environments/classic_control/cart_pole/
      environments/classic_control/mountain_car_continuous/ environments/classic_control/mountain_car/
      environments/classic_control/pendulum/
      environments/box2d/ environments/box2d/bipedal_walker/ environments/box2d/car_racing/ environments/box2d/lunar_lander/
      environments/toy_text/ environments/toy_text/blackjack/ environments/toy_text/taxi/
      environments/toy_text/cliff_walking/ environments/toy_text/frozen_lake/
      environments/mujoco/ environments/mujoco/ant/ environments/mujoco/half_cheetah/ environments/mujoco/hopper/
      environments/mujoco/humanoid_standup/ environments/mujoco/humanoid/ environments/mujoco/inverted_double_pendulum/
      environments/mujoco/inverted_pendulum/ environments/mujoco/pusher/ environments/mujoco/reacher/
      environments/mujoco/swimmer/ environments/mujoco/walker2d/
      environments/atari/
      tutorials/gymnasium_basics/ tutorials/gymnasium_basics/environment_creation/
      tutorials/gymnasium_basics/handling_time_limits/ tutorials/gymnasium_basics/implementing_custom_wrappers/
      tutorials/gymnasium_basics/load_quadruped_model/
      tutorials/training_agents/ tutorials/training_agents/action_masking_taxi/
      tutorials/training_agents/blackjack_q_learning/ tutorials/training_agents/frozenlake_q_learning/
      tutorials/training_agents/mujoco_reinforce/ tutorials/training_agents/vector_a2c/
    )
    self.links = {
      home: 'https://gymnasium.farama.org/',
      code: 'https://github.com/Farama-Foundation/Gymnasium'
    }

    html_filters.push 'gymnasium/entries', 'gymnasium/clean_html', 'sphinx/clean_html'

    options[:container] = 'article[role="main"]'
    # the introduction, the API reference, the environments and the
    # tutorials; not the release notes, the third-party listings and the
    # source code pages
    options[:only] = ['']
    options[:only_patterns] = [/\Aintroduction\//, /\Aapi\//, /\Aenvironments\//, /\Atutorials\//]
    options[:skip_patterns] = [/third[_-]party/, /\A_modules/, /\A_sources/]
    # Some pages link others without the trailing slash, which would scrape
    # them twice.
    options[:fix_urls] = ->(url) do
      url.sub(%r{\A(https://gymnasium\.farama\.org/v[\d.]+/(?:[^?#]*/)?[^/?#.]+)(?=[?#]|\z)}, '\\1/')
    end
    options[:max_image_size] = 300_000
    options[:rate_limit] = 300

    options[:attribution] = <<-HTML
      &copy; 2016&ndash;2022 OpenAI, &copy; 2022&ndash;2026 Farama Foundation<br>
      Licensed under the MIT License.
    HTML

    version '1.4' do
      self.release = '1.4.0'
      self.base_url = "https://gymnasium.farama.org/v#{self.release}/"
    end

    def get_latest_version(opts)
      get_latest_github_release('Farama-Foundation', 'Gymnasium', opts)
    end
  end
end
