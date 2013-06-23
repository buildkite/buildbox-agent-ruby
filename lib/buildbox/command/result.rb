# encoding: UTF-8

module Buildbox
  class Command::Result < Struct.new(:command, :output, :exit_status)
    def success?
      exit_status == 0
    end

    def failed?
      !success?
    end
  end
end
