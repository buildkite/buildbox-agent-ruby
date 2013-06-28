# encoding: UTF-8

module Buildbox
  class Command::Result < Struct.new(:command, :output, :exit_status)
  end
end
