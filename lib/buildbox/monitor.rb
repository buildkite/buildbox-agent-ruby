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
        # As the build can finish in between doing the update_build api_call
        # and checking to see if the build has finished, we make sure we use the
        # same finished_at timestamp throughout the entire method.
        finished_at = @build.finished_at

        updated_build = @api.update_build(@build.url, @build.started_at, finished_at,
                                          @build.output, @build.exit_status)

        if updated_build.state == 'canceled' && !@build.cancelling?
          Buildbox::Canceler.new(@build).async.cancel
        end

        if finished_at
          break
        else
          sleep 1
        end
      end
    end
  end
end
