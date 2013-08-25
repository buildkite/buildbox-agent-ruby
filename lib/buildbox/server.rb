module Buildbox
  class Server
    def initialize(config = Buildbox.config)
      @config = config
    end

    def start
      loop do
        worker_access_tokens.each do |access_token|
          Buildbox::Worker.new(access_token, api).work
        end

        @config.reload
        sleep 5
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
