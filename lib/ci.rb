require "ci/utf8"
require "ci/command"
require "ci/logger"
require "ci/result"
require "ci/build"
require "ci/version"
require "ci/client"
require "ci/api"
require "ci/worker"
require "ci/pid_file"

module CI
  require 'fileutils'
  require 'pathname'

  def self.root_path
    path = Pathname.new File.join(ENV['HOME'], ".ci")
    path.mkpath unless path.exist?

    Pathname.new(path)
  end

  def self.logger
    @logger ||= Logger.new(STDOUT)
  end
end
