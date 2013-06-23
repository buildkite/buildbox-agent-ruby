# encoding: UTF-8

module Buildbox
  class Build::Part
    attr_reader :uuid
    attr_accessor :output, :exit_status

    def initialize(uuid)
      @uuid   = uuid
      @output = ""
    end

    def success?
      exit_status == 0
    end

    def failed?
      !success?
    end
  end
end
