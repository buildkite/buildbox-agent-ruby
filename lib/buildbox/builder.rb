require 'celluloid'

module Buildbox
  class Builder
    include Celluloid
    include Celluloid::Logger

    attr_reader :build, :output

    def initialize(build)
      @build = build
    end

    def start
      info "Starting to build #{script.path} starting..."

      script.save

      build.output = ""
      output, exit_status = Command.run(command) { |chunk| build.output << chunk }

      build.output      = output
      build.exit_status = exit_status

      script.delete

      info "#{script.path} finished"
    end

    private

    def command
      %{chmod +x #{script.path} && #{environment} exec #{script.path}}
    end

    def script
      @script ||= Script.new(@build)
    end

    def environment
      @environment ||= Environment.new(@build.env)
    end
  end
end
