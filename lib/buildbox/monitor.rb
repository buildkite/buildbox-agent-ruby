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
        @api.update_build(@build) if @build.started?

        if @build.finished?
          break
        else
          sleep 1
        end
      end
    end
  end
end
