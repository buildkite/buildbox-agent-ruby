module Trigger
  class Result < Struct.new(:success, :output)
    alias :success? :success
  end
end
