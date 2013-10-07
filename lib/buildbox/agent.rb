require 'celluloid'

module Buildbox
  class Agent
    include Celluloid
    include Celluloid::Logger

    def initialize(access_token, api = Buildbox::API.new)
      @api          = api
      @access_token = access_token
    end

    def process
      return if @current_build

      @current_build = @api.next_build(@access_token)

      if @current_build
        @api.update_build(@access_token, @current_build, :agent_accepted => @access_token)

        Monitor.new(@current_build, @access_token, @api).async.monitor
        Runner.new(@current_build).start
      end

      @current_build = nil
    end

    private

    def scheduled_builds
      @api.agent(@access_token, :hostname => hostname, :version => Buildbox::VERSION)
      @api.scheduled_builds(@access_token)
    rescue Buildbox::API::AgentNotFoundError
      warn "Agent `#{@access_token}` does not exist"
      [] # return empty array to avoid breakage
    end

    def hostname
      `hostname`.chomp
    end
  end
end
