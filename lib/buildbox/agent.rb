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

      # Start off by letting each build know that it's been picked up
      # by an agent.
      builds.each do |build|
        @api.update_build(build, :agent_accepted => @access_token)
      end

      # Run the builds one at a time
      builds.each do |build|
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
