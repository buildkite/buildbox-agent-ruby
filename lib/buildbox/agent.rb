require 'celluloid'

module Buildbox
  class Agent
    include Celluloid
    include Celluloid::Logger

    def initialize(access_token, api = Buildbox::API.new)
      @api          = api
      @access_token = access_token
      @queue        = []
    end

    def process
      unless @processing
        @processing = true

        scheduled_builds.each { |build| @queue << build }

        while build = @queue.pop do
          # Let the agent know that we're about to start running this build
          @api.update_build(build, :agent_accepted => @access_token)

          Monitor.new(build, @api).async.monitor
          Runner.new(build).start
        end

        @processing = false
      end
    end

    private

    def scheduled_builds
      agent = @api.agent(@access_token, hostname)
      @api.scheduled_builds agent
    rescue Buildbox::API::AgentNotFoundError
      warn "Agent `#{@access_token}` does not exist"
      [] # return empty array to avoid breakage
    end

    def hostname
      `hostname`.chomp
    end
  end
end
