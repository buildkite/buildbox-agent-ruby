require 'rubygems'

require "buildbox/api"
require "buildbox/builder"
require "buildbox/command"
require "buildbox/configuration"
require "buildbox/environment"
require "buildbox/monitor"
require "buildbox/script"
require "buildbox/server"
require "buildbox/utf8"

require 'pathname'

module Buildbox
  def self.config
    @config ||= Configuration.new.tap(&:reload)
  end

  def self.root_path
    path = Pathname.new File.join(ENV['HOME'], ".buildbox")
    path.mkpath unless path.exist?

    Pathname.new(path)
  end
end
