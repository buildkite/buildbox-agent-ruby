require 'rubygems'
require 'hashie/mash'
require 'json'

module Buildbox
  class Configuration < Hashie::Mash
    def agent_access_tokens
      env_agents = ENV['BUILDBOX_WORKERS']

      if env_agents.nil?
        self[:agent_access_tokens] || []
      else
        env_agents.to_s.split(",")
      end
    end

    def api_key
      ENV['BUILDBOX_API_KEY'] || self[:api_key]
    end

    def api_endpoint
      ENV['BUILDBOX_API_ENDPOINT'] || self[:api_endpoint] || "https://api.buildbox.io/v1"
    end

    def check
      unless api_key
        puts "No api_key set. You can set it with\nbuildbox auth:login [api_key]"
        exit 1
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
      Buildbox.root_path.join("configuration.json")
    end
  end
end
