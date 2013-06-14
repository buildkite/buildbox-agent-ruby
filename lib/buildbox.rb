require "buildbox/utf8"
require "buildbox/command"
require "buildbox/result"
require "buildbox/build"
require "buildbox/version"
require "buildbox/client"
require "buildbox/api"
require "buildbox/queue"
require "buildbox/pid_file"
require "buildbox/configuration"
require "buildbox/auth"
require "buildbox/response"

module Buildbox
  require 'fileutils'
  require 'pathname'
  require 'logger'

  class << self
    def configuration
      @configuration ||= Configuration.load
    end

    def root_path
      path = Pathname.new File.join(ENV['HOME'], ".buildbox")
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
