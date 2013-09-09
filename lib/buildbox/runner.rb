require 'rubygems'
require 'celluloid'
require 'fileutils'
require 'yaml'

module Buildbox
  class Runner
    include Celluloid
    include Celluloid::Logger

    attr_reader :build

    class CommandFailedError < StandardError; end

    def initialize(build)
      @build = build
    end

    def run(*args)
      # Create the build part
      build_part = Build::Part.new(:command => args.join(' '), :output => '', :started_at => Time.now.utc)
      @build.parts << build_part

      # Run the command and capture output
      result = Command.run(*args, :environment => @build.env, :directory => @working_directory) do |chunk|
        build_part.output << chunk
      end

      # Set the output again because we may have missed some in the block
      build_part.output      = result.output
      build_part.exit_status = result.exit_status
      build_part.finished_at = Time.now.utc

      raise CommandFailedError unless build_part.success?

      build_part
    end

    def start
      info "Starting to build #{@build.namespace}/#{@build.id} starting..."

      # Ensure we have the right env variables needed to build
      %w(BUILDBOX_REPO BUILDBOX_COMMIT).each do |env|
        raise "Build is missing environment variable #{env}" unless @build.env[env]
      end

      @build.state = Build::State::STARTED

      # Ensure we have a working directory to run the build in
      @working_directory = @build.project.working_directory || default_working_directory
      FileUtils.mkdir_p(@working_directory)

      begin
        # Bootstrap version control and checkout the right commit
        bootstrap_version_control

        # Try and find a .buildbox.yml file
        buildbox_yml = File.join(@working_directory, '.buildbox.yml')

        if File.exist?(buildbox_yml)
          yaml = YAML.load_file(buildbox_yml)
          commands = [ *yaml['script'] ]
        else
          # Maybe there is a .buildbox file that can be executed?
          buildbox_script = File.join(@working_directory, '.buildbox')
          commands = [ buildbox_script ] if File.exist?(buildbox_script)
        end

        # Run the commands for the build
        if commands && commands.any?
          commands.each { |command| run command }
        else
        end
      rescue CommandFailedError
      end

      @build.state = Build::State::FINISHED
    end

    private

    def bootstrap_version_control
      unless File.exist?(File.join(@working_directory, '.git'))
        run "git", "clone", @build.env["BUILDBOX_REPO"], "."
      end

      run "git", "clean", "-fd"
      run "git", "fetch", "-q"
      run "git", "checkout", "-qf", @build.env["BUILDBOX_COMMIT"]
    end

    def default_working_directory
      Buildbox.root_path.join(@build.namespace)
    end
  end
end
