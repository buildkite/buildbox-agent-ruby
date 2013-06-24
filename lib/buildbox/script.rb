# encoding: UTF-8

module Buildbox
  class Script
    MAGICAL_LINE_REGEX = /(buildbox:(?:begin|end)\:\w{8}-\w{4}-\w{4}-\w{4}-\w{12}(?:\:\d+)?)/
    MAGICAL_LINE_DIVIDER_REGEX = /:/

    def self.parse(line)
      json = line.chomp.match(/buildbox-begin\:(.+)?\:buildbox-end/)[1]

      JSON.parse(json)
    end

    def self.matches?(line)
      !!line.chomp.match(/buildbox-begin\:(.+)\:buildbox-end/)
    end

    def self.split(chunk)
      chunk.split(/(buildbox-begin\:.+?\:buildbox-end)/)
    end

    def initialize
      @commands = []
    end

    def queue(identifier, command)
      @commands << { :identifier => identifier, :command => command }
    end

    def to_s
      script = ["#!/bin/bash", "set -e"]

      @commands.each do |item|
        script << magical_line(item.merge(:action => "begin"))
        script << item[:command]
        script << magical_line(item.merge(:action => "end", :exit_status => "$?"))
      end

      script.join("\n")
    end

    private

    def magical_line(json)
      line = [ "buildbox-begin", JSON.dump(json), "buildbox-end" ]

      %{echo #{line.join(":").inspect};}
    end
  end
end
