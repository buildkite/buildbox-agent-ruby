# encoding: UTF-8
require 'securerandom'

# The runner is responsibile for constructing the build script, and running it.
module Buildbox
  class Build::Runner
    def initialize(build, observer)
      @build    = build
      @observer = observer
      @script   = Buildbox::Build::Script.new
    end

    def run
      build_script && run_script
    end

    private

    def queue(command)
      @script.queue SecureRandom.uuid, command
    end

    def build_script
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

    def run_script
      current_result = nil

      Buildbox::Command.run(@script.to_s) do |chunk|
        parts = chunk.split(Buildbox::Build::Script::MAGICAL_LINE_REGEX)

        parts.each do |part|
          if part.match(Buildbox::Build::Script::MAGICAL_LINE_REGEX)
            sections = part.split(Buildbox::Build::Script::MAGICAL_LINE_DIVIDER_REGEX)

            p sections
          else
            p part
          end
        end
      end
    end

    def escape(string)
      string.to_s.inspect
    end
  end
end
