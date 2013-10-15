require 'pathname'
require 'logger'

module Buildbox
  autoload :API,           "buildbox/api"
  autoload :Build,         "buildbox/build"
  autoload :Command,       "buildbox/command"
  autoload :Canceler,      "buildbox/canceler"
  autoload :CLI,           "buildbox/cli"
  autoload :Configuration, "buildbox/configuration"
  autoload :Monitor,       "buildbox/monitor"
  autoload :Platform,      "buildbox/platform"
  autoload :Runner,        "buildbox/runner"
  autoload :Script,        "buildbox/script"
  autoload :Server,        "buildbox/server"
  autoload :UTF8,          "buildbox/utf8"
  autoload :Agent,         "buildbox/agent"
  autoload :VERSION,       "buildbox/version"

  def self.config
    @config ||= Configuration.new.tap(&:reload)
  end

  def self.logger
    @logger ||= Logger.new(STDOUT).tap { |logger| logger.level = Logger::INFO }
  end

  def self.logger=(logger)
    @logger = logger
  end

  def self.root_path
    path = Pathname.new File.join(Dir.home, ".buildbox")
    path.mkpath unless path.exist?

    Pathname.new(path)
  end
end
