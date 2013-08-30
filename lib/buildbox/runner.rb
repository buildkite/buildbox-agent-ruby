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

      FileUtils.mkdir_p(directory_path)
      File.open(script_path, 'w+') { |file| file.write(@build.script) }
      File.chmod(0777, script_path)

      info "Running script: #{script_path}"

      build.output = ""
      result = Command.script(script_path, :environment => @build.env,
                                           :directory   => directory_path) do |chunk|
        build.output << chunk
      end

      build.output      = result.output
      build.exit_status = result.exit_status

      File.delete(script_path)

      info "#{namespace} ##{@build.number} finished with exit status #{result.exit_status}"
    end

    private

    def directory_path
      @directory_path ||= Buildbox.root_path.join(namespace)
    end

    def script_path
      @script_path ||= Buildbox.root_path.join("buildbox-#{namespace.gsub(/\//, '-')}-#{@build.number}")
    end

    def namespace
      "#{@build.project.team.name}/#{@build.project.name}"
    end
  end
end
