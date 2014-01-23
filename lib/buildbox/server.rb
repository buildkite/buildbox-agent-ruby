require 'celluloid'

module Buildbox
  class Server
    INTERVAL = 5

    def initialize(config = Buildbox.config, logger = Buildbox.logger)
      @config = config
      @logger = logger
      @supervisors = []
      @iterations = 0
    end

    def start
      Celluloid.logger = @logger
      Celluloid::Actor[:artifact_poster_pool] = Artifact::Poster.pool

      agent_access_tokens.each do |access_token|
        @supervisors << Buildbox::Agent.supervise(access_token)

        @logger.info "Agent with access token `#{access_token}` has started."
      end

      before = ObjectSpace.count_objects

      loop do
        x = allocate_count(before) do
          @supervisors.each do |supervisor|
            supervisor.actors.first.async.process
          end

          # https://github.com/ruby-prof/ruby-prof

          GC.start

          wait INTERVAL
        end

        p x
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

    def allocate_count(before, &block)
      GC.disable
      yield
      after = ObjectSpace.count_objects
      after.each { |k,v| after[k] = v - before[k] }
      GC.enable
      after
    end
  end
end
