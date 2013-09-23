require 'celluloid'

module Buildbox
  class Server
    INTERVAL = 5

    def initialize(config = Buildbox.config, logger = Buildbox.logger)
      @config      = config
      @logger      = logger
      @supervisors = []
    end

    def start
      Celluloid.logger = @logger

      agent_access_tokens.each do |access_token|
        @supervisors << Buildbox::Agent.supervise(access_token)

        @logger.info "Agent with access token `#{access_token}` has started."
      end

      loop do
        @supervisors.each do |supervisor|
          supervisor.actors.first.async.process
        end

        wait INTERVAL
      end
    end

    private

    def wait(interval)
      @logger.debug "Sleeping for #{interval} seconds"

      sleep interval
    end

    def agent_access_tokens
      @config.agent_access_tokens
    end
  end
end
