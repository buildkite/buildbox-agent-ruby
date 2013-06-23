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
      Buildbox::Command.run(@script.to_s) do |chunk|
        parse_chunk(chunk)
      end

      @parts
    end

    private

    def parse_chunk(chunk)
      parts = chunk.split(Buildbox::Script::MAGICAL_LINE_REGEX)

      parts.each do |part|
        if is_buildbox_line?(part)
          buildbox, action, uuid, exit_status = split_buildbox_line(part)

          if action == 'begin'
            @parts << @current_part = Buildbox::Build::Part.new(uuid)
          elsif action == 'end'
            @current_part.output.strip!
            @current_part.exit_status = exit_status.to_i
          end
        elsif @current_part
          @current_part.output << part
        end
      end
    end

    def is_buildbox_line?(line)
      line.match(Buildbox::Script::MAGICAL_LINE_REGEX)
    end

    def split_buildbox_line(line)
      line.split(Buildbox::Script::MAGICAL_LINE_DIVIDER_REGEX)
    end
  end
end
