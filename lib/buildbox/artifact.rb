require 'securerandom'

module Buildbox
  class Artifact
    autoload :Poster,    "buildbox/artifact/poster"
    autoload :Collector, "buildbox/artifact/collector"
    autoload :Uploader,  "buildbox/artifact/uploader"

    attr_reader :id, :name, :path
    attr_accessor :remote_id, :upload_instructions

    def self.create(name, path)
      new(SecureRandom.uuid, name, path)
    end

    def initialize(id, name, path)
      @id   = id
      @name = name
      @path = path
    end

    def basename
      File.basename(@path)
    end

    def as_json
      { :id => @id, :name => @name, :path => @path, :file_size => File.size(@path) }
    end
  end
end
