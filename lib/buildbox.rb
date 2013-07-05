require "buildbox/api"
require "buildbox/api/response"

require "buildbox/build"
require "buildbox/build/observer"
require "buildbox/build/null_observer"
require "buildbox/build/console_observer"
require "buildbox/build/script"
require "buildbox/build/runner"
require "buildbox/build/part"

require "buildbox/command"
require "buildbox/command/result"

require "buildbox/utf8"
require "buildbox/version"
require "buildbox/worker"
require "buildbox/pid_file"
require "buildbox/script"

require "buildbox/client"
require "buildbox/client/configuration"

require "buildbox/auth"

module Buildbox
  require 'fileutils'
  require 'pathname'
  require 'logger'

  class << self
    def configuration
      @configuration ||= Client::Configuration.load
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
