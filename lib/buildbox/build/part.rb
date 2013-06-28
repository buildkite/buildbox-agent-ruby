# encoding: UTF-8

module Buildbox
  class Build::Part
    attr_reader :uuid, :command
    attr_accessor :output, :exit_status

    def initialize(uuid, command)
      @uuid    = uuid
      @command = command
      @output  = ""
    end

    def success?
      exit_status == 0
    end

    def failed?
      !success?
    end

    def as_json
      { :uuid        => @uuid,
        :command     => @command,
        :output      => @output,
        :exit_status => @exit_status }
    end
  end
end
