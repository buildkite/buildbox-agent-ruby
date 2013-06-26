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

      # if one of the commands inside the script returns an exit status,
      # nothing else will run. therefore we can assume that all the previous
      # commands have an exit status of 0. the exit status of the whole script
      # is then the exit status of the last command run.
      @current_part.exit_status = result.exit_status if @current_part

      @parts
    end

    private

    # for each chunk of the output, detect if we've seen a buildbox magical
    # line which contains information about the current command.
    def parse_chunk(chunk)
      parts = Buildbox::Script.split(chunk)

      parts.each do |part|
        if Buildbox::Script.matches?(part)
          # if we've intercepted a new magical buildbox command, and we hae a current part
          # in the mix alreadt, that means the previous one finished successfully.
          if @current_part
            @current_part.output      = @current_part.output.strip.chomp
            @current_part.exit_status = 0
            @current_part = nil
          end

          info = Buildbox::Script.parse(part)
          @parts << @current_part = Buildbox::Build::Part.new(info['identifier'], info['command'])
          @observer.started(@current_part)
        elsif @current_part
          @current_part.output << part

          @observer.updated(@current_part)
        end
      end
    end
  end
end
