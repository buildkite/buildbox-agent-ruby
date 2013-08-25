require 'rubygems'
require 'celluloid'
require 'fileutils'

module Buildbox
  class Runner
    include Celluloid
    include Celluloid::Logger

    attr_reader :build

    def initialize(build)
      @build = build
    end

    def start
      info "Starting to build #{namespace}/#{@build.number} starting..."
      info "Running command: #{command}"

      FileUtils.mkdir_p(directory_path)
      File.open(script_path, 'w+') { |file| file.write(@build.script) }

      build.output = ""
      result = Command.run(command, :directory => directory_path) do |chunk|
        build.output << chunk
      end

      build.output      = result.output
      build.exit_status = result.exit_status

      File.delete(script_path)

      info "#{namespace}/#{@build.number} finished with exit status #{result.exit_status}"
    end

    private

    def command
      export = environment.any? ? "export #{environment};" : ""

      "#{export} chmod +x #{script_path} && #{script_path}"
    end

    def directory_path
      @directory_path ||= Buildbox.root_path.join(namespace)
    end

    def script_path
      @script_path ||= Buildbox.root_path.join("buildbox-#{namespace.gsub(/\//, '-')}-#{@build.number}")
    end

    def namespace
      "#{@build.project.team.name}/#{@build.project.name}"
    end

    def environment
      @environment ||= Environment.new(@build.env)
    end
  end
end
