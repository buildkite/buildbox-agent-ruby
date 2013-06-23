# encoding: UTF-8
require 'securerandom'

# Generates a script that represents the steps to run for this build
module Buildbox
  class Build::Script
    def initialize(build)
      @build  = build
      @script = Buildbox::Script.new
    end

    def to_s
      construct_script && @script.to_s
    end

    private

    def construct_script
      unless @build.path.join(".git").exist?
        queue %{mkdir -p #{escape @build.path}}
        queue %{git clone #{escape @build.repository} #{escape @build.path} -q}
      end

      queue %{cd #{escape @build.path}}
      queue %{git clean -fd}
      queue %{git fetch -q}
      queue %{git checkout -qf #{escape @build.commit}}

      @build.commands.each do |command|
        queue command
      end
    end

    def queue(command)
      @script.queue SecureRandom.uuid, command
    end

    def escape(string)
      string.to_s.inspect
    end
  end
end
