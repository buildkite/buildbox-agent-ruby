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
      info "Starting to build #{@build.namespace}/#{@build.id} starting..."

      FileUtils.mkdir_p(directory_path)
      File.open(script_path, 'w+') { |file| file.write(@build.script) }
      File.chmod(0777, script_path)

      info "Running script: #{script_path}"

      @build.started_at = Time.now.utc

      build.output = ""
      result = Command.run(script_path, :environment => @build.env, :directory => directory_path) do |chunk|
        build.output << chunk
      end

      build.output      = result.output
      build.exit_status = result.exit_status

      File.delete(script_path)

      @build.finished_at = Time.now.utc

      info "#{@build.namespace} ##{@build.id} finished with exit status #{result.exit_status}"
    end

    private

    def directory_path
      @directory_path ||= Buildbox.root_path.join(@build.namespace)
    end

    def script_path
      @script_path ||= Buildbox.root_path.join("buildbox-#{@build.namespace.gsub(/\//, '-')}-#{@build.id}")
    end
  end
end
