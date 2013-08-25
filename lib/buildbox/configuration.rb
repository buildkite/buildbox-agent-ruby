require 'rubygems'
require 'hashie/dash'
require 'json'

module Buildbox
  class Configuration < Hashie::Dash
    property :worker_access_tokens, :default => []
    property :api_endpoint,         :default => "https://api.buildbox.io/v1"

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
