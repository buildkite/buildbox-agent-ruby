require 'rubygems'
require 'celluloid'
require 'tempfile'
require 'fileutils'

module Buildbox
  class Builder
    include Celluloid
    include Celluloid::Logger

    attr_reader :build

    def initialize(build)
      @build = build
    end

    def start
      info "Starting to build #{namespace}/#{@build.number} starting..."

      FileUtils.mkdir_p(directory_path)

      build.output = ""
      result = Command.run(command, :directory => directory_path) do |chunk|
        build.output << chunk
      end

      build.output      = result.output
      build.exit_status = result.exit_status

      info "#{namespace}/#{@build.number} finished"
    end

    private

    def command
      %{echo #{@build.script.inspect} > #{script_path} && chmod +x #{script_path} && #{environment} exec #{script_path}}
    end

    def directory_path
      @directory_path ||= Buildbox.root_path.join(namespace)
    end

    def script_path
      @script_path ||= Tempfile.new("buildbox-#{namespace.gsub(/\//, '-')}-#{@build.number}").path
    end

    def namespace
      "#{@build.project.team.name}/#{@build.project.name}"
    end

    def environment
      @environment ||= Environment.new(@build.env)
    end
  end
end
