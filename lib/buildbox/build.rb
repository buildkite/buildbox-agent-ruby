# encoding: UTF-8

module Buildbox
  class Build
    attr_reader :uuid, :repository, :commit, :commands

    def initialize(options)
      @uuid       = options[:uuid]
      @repository = options[:repository]
      @commit     = options[:commit]
      @config     = options[:config]
    end

    def commands
      [*@config[:script]]
    end

    def path
      Buildbox.root_path.join(folder_name)
    end

    private

    def folder_name
      @repository.gsub(/[^a-zA-Z0-9]/, '-')
    end
  end
end
