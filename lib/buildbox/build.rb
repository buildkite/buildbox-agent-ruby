# encoding: UTF-8

module Buildbox
  class Build
    attr_reader :uuid, :repository, :commit, :commands

    def initialize(options)
      @uuid       = options[:uuid]
      @repository = options[:repository]
      @commit     = options[:commit]
      @config     = options[:config]
      @failed     = false
      @results    = []
    end

    def commands
      [*@config[:script]]
    end

    def path
      Buildbox.root_path.join folder_name
    end

    def start(observer = nil)
    end

    private

    def folder_name
      @repository.gsub(/[^a-zA-Z0-9]/, '-')
    end

    def run(command)
      # don't run anoy more commands if the build has failed
      # at one of the steps
      return if @failed

      path    = build_path if build_path.exist?
      started = false

      result = Buildbox::Command.new(path).run(command) do |result, chunk|
        if started
          @observer.chunk(result)
          @results << result
        else
          @observer.started(result)
          started = true
        end
      end

      @observer.finished(result)

      # flag the build as failing, so we don't run any more commands.
      # this is a little hacky.
      @failed = true unless result.success?

      result
    end
  end
end
