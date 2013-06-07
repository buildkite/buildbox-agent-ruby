module Buildbox
  class Result < Struct.new(:output, :exit_status)
    def success?
      exit_status == 0
    end
  end
end
