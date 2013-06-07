module Buildbox
  class Configuration
    def self.load(*args)
      new(*args).tap &:reload
    end

    require 'json'

    attr_accessor :endpoint
    attr_accessor :use_ssl
    attr_accessor :api_version
    attr_accessor :repositories

    def initialize
      @use_ssl       = true
      @endpoint      = 'api.buildboxci.com'
      @api_version   = 1
      @repositories = []
    end

    def save
      File.open(path, 'w+') do |file|
        file.write(to_json)
      end
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
      JSON.generate(:endpoint => endpoint,
                    :use_ssl => use_ssl,
                    :api_version => api_version,
                    :repositories => repositories)
    end

    def read
      JSON.parse(path.read)
    end

    def path
      Buildbox.root_path.join("configuration.json")
    end
  end
end
