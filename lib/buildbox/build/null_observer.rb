# encoding: UTF-8

module Buildbox
  class Build::NullObserver
    def started(result)
    end

    def chunk(result)
    end

    def finished(result)
    end
  end
end
