module Buildbox
  class Configuration
    def self.load(*args)
      new(*args).tap &:reload
    end

    require 'json'

    attr_accessor :worker
    attr_accessor :api_key
    attr_accessor :endpoint
    attr_accessor :use_ssl
    attr_accessor :api_version

    def initialize
      @use_ssl       = true
      @endpoint      = 'api.buildbox.io'
      @api_version   = 1
    end

    def update(key, value)
      self.public_send("#{key}=", value)
      save
    end

    def save
      File.open(path, 'w+') do |file|
        file.write(to_json)
      end
      Buildbox.logger.debug "Configuration saved to `#{path}`"
    end

    def reload
      json = if path.exist?
               read
             else
               save && read
             end

      json.each_pair do |key, value|
        self.public_send("#{key}=", value)
      end
    end

    private

    def to_json
      JSON.pretty_generate(:endpoint => endpoint,
                           :use_ssl => use_ssl,
                           :api_version => api_version,
                           :api_key => api_key,
                           :worker => worker)
    end

    def read
      Buildbox.logger.debug "Reading configuration `#{path}`"

      JSON.parse(path.read)
    end

    def path
      Buildbox.root_path.join("configuration.json")
    end
  end
end
