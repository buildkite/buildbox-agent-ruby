# encoding: UTF-8

module Buildbox
  class Command::Result
    require 'securerandom'

    attr_reader :uuid, :command
    attr_accessor :finished, :exit_status

    def initialize(command)
      @uuid     = SecureRandom.uuid
      @output   = ""
      @finished = false
      @command  = command
    end

    def finished?
      finished
    end

    def success?
      exit_status == 0
    end

    def append(chunk)
      @output += Buildbox::UTF8.clean(chunk)
    end

    def output
      @output.chomp
    end

    def as_json
      { :uuid        => @uuid,
        :command     => @command,
        :output      => output,
        :exit_status => @exit_status }
    end
  end
end
