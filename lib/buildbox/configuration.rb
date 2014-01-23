require 'json'

module Buildbox
  class Configuration
    def agent_access_tokens
      env_agents = ENV['BUILDBOX_AGENTS']

      if env_agents.nil?
        self[:agent_access_tokens] || []
      else
        env_agents.to_s.split(",")
      end
    end

    def api_endpoint
      endpoint = ENV['BUILDBOX_API_ENDPOINT'] || self[:api_endpoint] || "https://agent.buildbox.io/v1"

      # hack to update legacy endpoints
      if endpoint == "https://api.buildbox.io/v1"
        self.api_endpoint = "https://agent.buildbox.io/v1"
        save
        api_endpoint
      else
        endpoint
      end
    end

    def update(attributes)
      attributes.each_pair { |key, value| self[key] = value }
      save
    end

    def save
      File.open(path, 'w+') { |file| file.write(pretty_json) }
    end

    def reload
      if path.exist?
        read_and_load
      else
        save && read_and_load
      end
    end

    private

    def pretty_json
      JSON.pretty_generate(self)
    end

    def read_and_load
      merge! JSON.parse(path.read)
    end

    def path
      Buildbox.home_path.join("configuration.json")
    end
  end
end
