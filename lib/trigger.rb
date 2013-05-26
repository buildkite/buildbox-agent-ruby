require "trigger/utf8"
require "trigger/command"
require "trigger/result"
require "trigger/build"
require "trigger/version"
require "trigger/client"
require "trigger/api"
require "trigger/worker"
require "trigger/pid_file"
require "trigger/configuration"

module Trigger
  require 'fileutils'
  require 'pathname'
  require 'logger'

  class << self
    attr_accessor :configuration

    def configure
      self.configuration ||= Configuration.new
      yield(configuration)
    end

    def root_path
      path = Pathname.new File.join(ENV['HOME'], ".trigger")
      path.mkpath unless path.exist?

      Pathname.new(path)
    end

    def logger=(logger)
      @logger = logger
    end

    def logger
      @logger ||= Logger.new(STDOUT)
    end
  end
end
