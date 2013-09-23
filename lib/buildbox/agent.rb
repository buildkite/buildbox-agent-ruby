require 'celluloid'

module Buildbox
  class Agent
    include Celluloid
    include Celluloid::Logger

    def initialize(access_token, api = Buildbox::API.new)
      @api          = api
      @access_token = access_token
    end

    def work
      builds = scheduled_builds

      # Run the builds one at a time
      builds.each do |build|
        # Let the agent know that we're about to start working on this build
        @api.update_build(build, :agent_accepted => @access_token)

        Monitor.new(build, @api).async.monitor
        Runner.new(build).start
      end
    end

    private

    def scheduled_builds
      agent = @api.agent(@access_token, hostname)
      @api.scheduled_builds agent
    rescue Buildbox::API::AgentNotFoundError
      warn "Agent `#{@access_token}` doesn't exist"
      [] # return empty array to avoid breakage
    end

    def hostname
      `hostname`.chomp
    end
  end
end
