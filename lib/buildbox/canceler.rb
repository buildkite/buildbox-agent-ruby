module Buildbox
  class Canceler
    def self.cancel(build)
      new(build).cancel
    end

    def initialize(build)
      @build = build
    end

    def cancel
      @build.cancel_started = true
      p "ZOMG CANCEL #{@build.id}"
      p "============================"
    end
  end
end
