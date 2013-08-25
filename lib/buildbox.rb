require 'pathname'

module Buildbox
  autoload :API,           "buildbox/api"
  autoload :Build,         "buildbox/build"
  autoload :Command,       "buildbox/command"
  autoload :CLI,           "buildbox/cli"
  autoload :Configuration, "buildbox/configuration"
  autoload :Environment,   "buildbox/environment"
  autoload :Monitor,       "buildbox/monitor"
  autoload :Runner,        "buildbox/runner"
  autoload :Script,        "buildbox/script"
  autoload :Server,        "buildbox/server"
  autoload :UTF8,          "buildbox/utf8"
  autoload :Worker,        "buildbox/worker"
  autoload :VERSION,       "buildbox/version"

  def self.config
    @config ||= Configuration.new.tap(&:reload)
 end

  def self.root_path
    path = Pathname.new File.join(ENV['HOME'], ".buildbox")
    path.mkpath unless path.exist?

    Pathname.new(path)
  end
end
