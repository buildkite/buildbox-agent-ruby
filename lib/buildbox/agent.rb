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

      if @current_build = next_build
        @api.update_build(@access_token, @current_build, :agent_accepted => @access_token)

        Monitor.new(@current_build, @access_token, @api).async.monitor
        Runner.new(@current_build).start
      end

      @current_build = nil
    end

    private

    def next_build
      @api.agent(@access_token, :hostname => hostname, :version => Buildbox::VERSION)
      @api.next_build(@access_token)
    rescue Buildbox::API::AgentNotFoundError
      warn "Agent `#{@access_token}` does not exist"
      nil
    end

    def hostname
      `hostname`.chomp
    end
  end
end
