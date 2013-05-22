require "trigger/utf8"
require "trigger/command"
require "trigger/result"
require "trigger/build"
require "trigger/version"
require "trigger/client"
require "trigger/api"
require "trigger/worker"
require "trigger/pid_file"

module Trigger
  require 'fileutils'
  require 'pathname'
  require 'logger'

  def self.root_path
    path = Pathname.new File.join(ENV['HOME'], ".trigger")
    path.mkpath unless path.exist?

    Pathname.new(path)
  end

  def self.logger=(logger)
    @logger = logger
  end

  def self.logger
    @logger ||= Logger.new(STDOUT)
  end
end
