# encoding: UTF-8

module Buildbox
  class Build::Part
    attr_reader :uuid
    attr_accessor :output, :exit_status

    def initialize(uuid)
      @uuid   = uuid
      @output = ""
    end
  end
end
