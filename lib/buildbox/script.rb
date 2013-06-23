# encoding: UTF-8

module Buildbox
  class Script
    MAGICAL_LINE_REGEX = /(buildbox:(?:begin|end)\:\w{8}-\w{4}-\w{4}-\w{4}-\w{12}(?:\:\d+)?)/
    MAGICAL_LINE_DIVIDER_REGEX = /:/

    def initialize
      @commands = []
    end

    def queue(identifier, command)
      @commands << [ identifier, command ]
    end

    def to_s
      buffer = []

      @commands.each do |command|
        identifier, line = command

        buffer << magical_line("begin", identifier, line)
        buffer << "#{line};"
        buffer << magical_line("end", identifier, line, "$?")
      end

      buffer.join("\n")
    end

    private

    def magical_line(action, info, command, extra = nil)
      line = [ "buildbox", action, info ]
      line << extra if extra

      %{echo #{line.join(":").inspect};}
    end
  end
end
