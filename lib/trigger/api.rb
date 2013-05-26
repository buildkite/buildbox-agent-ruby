module Trigger
  class API
    require 'net/http'
    require 'openssl'
    require 'json'

    def initialize
    end

    def update(build)
      response = post("repos/a8001481-3bb9-4034-915f-569f6ca664b5/builds/#{build.uuid}")
    end

    def scheduled
      response = get("repos/a8001481-3bb9-4034-915f-569f6ca664b5/builds/scheduled")
      json     = JSON.parse(response.body)

      json['response']['builds'].map do |build|
        # really smelly way of converting keys to symbols
        Build.new(Hash[build.map{ |k, v| [k.to_sym, v] }])
      end
    end

    private

    def http(uri)
      Net::HTTP.new(uri.host, uri.port).tap do |http|
        http.use_ssl     = uri.scheme == "https"
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
    end

    def get(path)
      uri     = URI.parse(endpoint(path))
      request = Net::HTTP::Get.new(uri.request_uri)

      http(uri).request(request)
    end

    def put(path, data)
      uri     = URI.parse(endpoint(path))
      request = Net::HTTP::Put.new(uri.request_uri, { 'Content-Type' =>'application/json' })
      request.set_form_data data

      http(uri).request(request)
    end

    def endpoint(path)
      (Trigger.configuration.use_ssl ? "https://" : "http://") +
        "#{Trigger.configuration.endpoint}/v#{Trigger.configuration.api_version}/#{path}"
    end
  end
end
