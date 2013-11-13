require 'securerandom'

module Buildbox
  class Artifact
    autoload :Poster,    "buildbox/artifact/poster"
    autoload :Collector, "buildbox/artifact/collector"
    autoload :Uploader,  "buildbox/artifact/uploader"

    attr_reader :id, :name, :path
    attr_accessor :remote_id, :upload_instructions

    def self.create(glob_path, name, path, original_path)
      new(SecureRandom.uuid, glob_path, name, path, original_path)
    end

    def initialize(id, glob_path, name, path, original_path)
      @id            = id
      @glob_path     = glob_path
      @name          = name
      @path          = path
      @original_path = original_path
    end

    def basename
      File.basename(@path)
    end

    def as_json
      { :id            => @id,
        :glob_path     => @glob_path,
        :name          => @name,
        :path          => @path,
        :original_path => @original_path,
        :file_size     => File.size(@path) }
    end
  end
end
