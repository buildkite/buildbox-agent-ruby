module Trigger
  class API
    require 'net/http'
    require 'openssl'
    require 'json'

    def initialize
    end

    def scheduled
      uri              = endpoint_uri("repos/a8001481-3bb9-4034-915f-569f6ca664b5/builds/scheduled")
      http             = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl     = uri.scheme == "https"
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE

      request      = Net::HTTP::Get.new(uri.request_uri, { 'Content-Type' =>'application/json' })
      # request      = Net::HTTP::Post.new(uri.request_uri, { 'Content-Type' =>'application/json' })
      # request.body = JSON.generate(post_data)

      response = http.request(request)
      json     = JSON.parse(response.body)

      json['response']['builds'].map do |build|
        # really smelly way of converting keys to symbols
        Build.new(Hash[build.map{ |k, v| [k.to_sym, v] }])
      end
    end

    private

    def endpoint_uri(path)
      URI.parse(endpoint(path))
    end

    def endpoint(path)
      (Trigger.configuration.use_ssl ? "https://" : "http://") +
        "#{Trigger.configuration.endpoint}/v#{Trigger.configuration.api_version}/#{path}"
    end
  end
end
