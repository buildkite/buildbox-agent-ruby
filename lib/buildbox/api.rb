require 'faraday'
require 'faraday_middleware'
require 'hashie/mash'
require 'delegate'

module Buildbox
  class API
    # Faraday uses debug to show response information, but when the agent is in
    # DEBUG mode, it's kinda useless noise. So we use a ProxyLogger to only push
    # the information we care about to the logger.
    class ProxyLogger
      def initialize(logger)
        @logger = logger
      end
      def info(*args)
        @logger.debug(*args)
      end

      def debug(*args)
        # no-op
      end
    end

    class AgentNotFoundError < Faraday::Error::ClientError; end
    class ServerError < Faraday::Error::ClientError; end

    def initialize(config = Buildbox.config, logger = Buildbox.logger)
      @config = config
      @logger = logger
    end

    def authenticate(api_key)
      @api_key = api_key

      get("user")
    end

    def agent(access_token, hostname)
      put("agents/#{access_token}", :hostname => hostname)
    rescue Faraday::Error::ClientError => e
      if e.response[:status] == 404
        raise AgentNotFoundError.new(e, e.response)
      else
        raise ServerError.new(e, e.response)
      end
    end

    def scheduled_builds(agent)
      get(agent.scheduled_builds_url).map { |build| Buildbox::Build.new(build) }
    end

    def update_build(build, options)
      put(build.url, options)
    end

    private

    def connection
      @connection ||= Faraday.new(:url => @config.api_endpoint) do |faraday|
        faraday.basic_auth @api_key || @config.api_key, ''
        faraday.request :retry
        faraday.request :json

        faraday.response :logger, ProxyLogger.new(@logger)
        faraday.response :mashify

        # JSON needs to come after mashify as it needs to run before the mashify
        # middleware.
        faraday.response :json
        faraday.response :raise_error

        faraday.adapter Faraday.default_adapter

        # Set some sensible defaults on the adapter.
        faraday.options[:timeout]      = 60
        faraday.options[:open_timeout] = 60
      end
    end

    def post(path, body = {})
      connection.post(path) do |request|
        request.body                    = body
        request.headers['Content-Type'] = 'application/json'
      end.body
    end

    def put(path, body = {})
      connection.put(path) do |request|
        request.body = body
      end.body
    end

    def get(path)
      connection.get(path).body
    end
  end
end
