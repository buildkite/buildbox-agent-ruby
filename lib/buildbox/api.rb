module Buildbox
  class API
    require 'net/http'
    require 'openssl'
    require 'json'

    def initialize(options)
      @options = options
    end

    def crash(exception, information = {})
      payload = {
        :exception => exception.class.name,
        :message   => exception.message,
        :backtrace => exception.backtrace,
        :meta      => {}
      }

      payload[:meta][:worker_uuid] = worker_uuid if worker_uuid
      payload[:meta][:build_uuid]  = information[:build] if information[:build]
      payload[:meta][:client_version] = Buildbox::VERSION

      request(:post, "crashes", payload)
    end

    def register(payload)
      request(:post, "workers", payload)
    end

    def login
      request(:get, "user")
    end

    def builds(options = {})
      request(:get, "workers/#{worker_uuid}/builds")
    end

    def update_build_state(build_uuid, state)
      Thread.new { request(:put, "workers/#{worker_uuid}/builds/#{build_uuid}", :state => state) }
    end

    def update_build_result(build_uuid, result_uuid, attributes)
      Thread.new { request(:put, "workers/#{worker_uuid}/builds/#{build_uuid}/results/#{result_uuid}", attributes) }
    end

    private

    def http(uri)
      Net::HTTP.new(uri.host, uri.port).tap do |http|
        http.use_ssl     = uri.scheme == "https"
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
    end

    def request(method, path, payload = nil)
      klass   = case method
                when :get  then Net::HTTP::Get
                when :put  then Net::HTTP::Put
                when :post then Net::HTTP::Post
                else raise "No request class defined for `#{method}`"
                end

      uri     = URI.parse(endpoint(path))
      request = klass.new(uri.request_uri, 'Content-Type' => 'application/json',
                                           'Accept' => 'application/json')

      if payload.nil?
        Buildbox.logger.debug "#{method.to_s.upcase} #{uri}"
      else
        request.body = JSON.dump(payload)
        Buildbox.logger.debug "#{method.to_s.upcase} #{uri} #{payload.inspect}"
      end

      Response.new http(uri).request(request)
    end

    def worker_uuid
      Buildbox.configuration.worker_uuid
    end

    def endpoint(path)
      (Buildbox.configuration.use_ssl ? "https://" : "http://") +
        "#{Buildbox.configuration.endpoint}/v#{Buildbox.configuration.api_version}/#{path}"
    end
  end
end
