module Buildbox
  class Server
    INTERVAL = 5

    def initialize(config = Buildbox.config, logger = Buildbox.logger)
      @config = config
      @logger = logger
    end

    def start
      loop do
        @config.check
        @config.reload

        worker_access_tokens.each do |access_token|
          Buildbox::Worker.new(access_token, api).work
        end

        @logger.info "Sleeping for #{INTERVAL} seconds"
        sleep INTERVAL
      end
    end

    private

    def api
      @api ||= Buildbox::API.new
    end

    def worker_access_tokens
      @config.worker_access_tokens
    end
  end
end
