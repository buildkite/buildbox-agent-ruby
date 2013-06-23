# encoding: UTF-8

# The runner generates a script and runs it
module Buildbox
  class Build::Runner
    def self.run(build, observer)
      new(build, observer).run
    end

    def initialize(build, observer)
      @build    = build
      @observer = observer
      @script   = Buildbox::Build::Script.new(@build)

      @parts        = []
      @current_part = nil
    end

    def run
      result = Buildbox::Command.run(@script.to_s) do |chunk|
        parse_chunk(chunk)
      end

      @parts
    end

    private

    def parse_chunk(chunk)
      parts = Buildbox::Script.split(chunk)

      parts.each do |part|
        if Buildbox::Script.matches?(part)
          info = Buildbox::Script.parse(part)

          if info['action'] == 'begin'
            @parts << @current_part = Buildbox::Build::Part.new(info['identifier'], info['command'])

            @observer.started(@current_part)
          elsif info['action'] == 'end'
            @current_part.output      = @current_part.output.strip.chomp
            @current_part.exit_status = info['exit_status'].to_i

            @observer.finished(@current_part)
            @current_part = nil
          end
        elsif @current_part
          @current_part.output << part

          @observer.updated(@current_part)
        end
      end
    end
  end
end
