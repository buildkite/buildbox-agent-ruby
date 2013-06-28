# encoding: UTF-8

module Buildbox
  class Script
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

    def queue(id, command)
      @commands << { :id => id, :command => command }
    end

    def to_s
      script = ["#!/bin/bash", "set -e"]

      @commands.each do |item|
        payload = "buildbox-begin:#{JSON.dump(item)}:buildbox-end"

        script << %{echo #{payload.inspect};}
        script << item[:command]
      end

      script.join("\n")
    end
  end
end
