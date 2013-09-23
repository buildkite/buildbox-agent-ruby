module Buildbox
  class Server
    INTERVAL = 5

    def initialize(config = Buildbox.config, logger = Buildbox.logger)
      @config = config
      @logger = logger
      @agents = []
    end

    def start
      agent_access_tokens.each do |access_token|
        @agents << Buildbox::Agent.new(access_token)
      end

      loop do
        @agents.each { |agent| agent.async.work }

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
