require 'celluloid'

module Buildbox
  class Monitor
    include Celluloid

    def initialize(build, access_token, api)
      @build        = build
      @access_token = access_token
      @api          = api
    end

    def monitor
      loop do
        if @build.started?
          # As the build can finish in between doing the update_build api_call
          # and checking to see if the build has finished, we make sure we use the
          # same finished_at timestamp throughout the entire method.
          finished_at = @build.finished_at

          updated_build = @api.update_build(@access_token, @build, :started_at  => @build.started_at,
                                                                   :finished_at => finished_at,
                                                                   :output      => @build.output,
                                                                   :exit_status => @build.exit_status)

          if updated_build['state'] == 'canceled' && !@build.cancelling?
            Buildbox::Canceler.new(@build).async.cancel
          end

          break if finished_at
        end

        sleep 1
      end
    end
  end
end
