# encoding: UTF-8

module Buildbox
  class Build::ConsoleObserver
    def started(result)
      print "\033[32m$\033[0m #{result.command}"
    end

    def updated(result, partial)
      print partial
    end

    def finished(result)
    end
  end
end
