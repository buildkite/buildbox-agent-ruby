require 'rubygems'
require 'faraday'
require 'faraday_middleware'
require 'hashie/mash'

module Buildbox
  class API
    RETRYABLE_EXCEPTIONS = [ 'Timeout::Error', 'Errno::EINVAL', 'Errno::ECONNRESET', 'EOFError', 'Net::HTTPBadResponse',
                             'Net::HTTPHeaderSyntaxError', 'Net::ProtocolError', 'Errno::EPIPE' ]

    def initialize(config = Buildbox.config)
      @config  = config
    end

    def authenticate(api_key)
      @api_key = api_key
      get("user")
    end

    def agent(access_token, hostname)
      put("agents/#{access_token}", :hostname => hostname)
    end

    def scheduled_builds(project)
      get(project.scheduled_builds_url).map { |build| Buildbox::Build.new(build) }
    end

    def update_build(url, started_at, finished_at, output, exit_status)
      put(url, :started_at  => started_at,
               :finished_at => finished_at,
               :output      => output,
               :exit_status => exit_status)
    end

    private

    def connection
      @connection ||= Faraday.new(:url => @config.api_endpoint) do |faraday|
        faraday.basic_auth @api_key || @config.api_key, ''

        # Retry when some random things happen
        faraday.request :retry, :max => 3, :interval => 1, :exceptions => RETRYABLE_EXCEPTIONS

        faraday.request  :json

        faraday.response :logger, Buildbox.logger
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
        request.body = body
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
