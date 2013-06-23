# encoding: UTF-8

module Buildbox
  class Build::Script
    MAGICAL_LINE_REGEX = /(buildbox:(?:begin|end)(?:\:\d+)?:\w{8}-\w{4}-\w{4}-\w{4}-\w{12})/
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
        buffer << magical_line("end", identifier, line)
      end

      buffer.join("\n")
    end

    private

    def magical_line(action, identifier, command)
      %{echo "buildbox:#{action}:#{identifier}";}
    end
  end
end
