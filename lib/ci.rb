require "ci/utf8"
require "ci/command"
require "ci/logger"
require "ci/result"
require "ci/build"
require "ci/version"

module CI
  require 'fileutils'
  require 'pathname'

  def self.root_path
    path = Pathname.new File.join(ENV['HOME'], ".ci")
    path.mkpath unless path.exist?

    Pathname.new(path)
  end
end
