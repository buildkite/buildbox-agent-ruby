require 'rubygems'
require 'celluloid'

module Buildbox
  class Monitor
    include Celluloid

    def initialize(build, api)
      @build = build
      @api   = api
    end

    def monitor
      loop do
        # There is an edge case where the build finishes between making the
        # update_build http call, and breaking. So to make sure we're using the
        # same build object throughout this call, we can just deep dup it.
        build = Marshal.load(Marshal.dump(@build))
        @api.update_build(build) if build.started? || build.finished?

        if build.finished?
          break
        else
          sleep 3 # 3 seconds seems reasonable for now
        end
      end
    end
  end
end
