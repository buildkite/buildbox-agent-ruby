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

        if build.started? || build.finished?
          new_build = @api.update_build(build)

          # Try and cancel the build if we haven't tried already
          if new_build.state == 'canceled' && !@build.cancelling?
            Buildbox::Canceler.cancel(@build)
          end
        end

        if build.finished?
          break
        else
          sleep 2 # 2 seconds seems reasonable for now
        end
      end
    end
  end
end
