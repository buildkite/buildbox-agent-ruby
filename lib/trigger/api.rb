module Trigger
  class API
    require 'net/http'
    require 'openssl'
    require 'json'

    def update(build, data)
      put("repos/#{build.repository_uuid}/builds/#{build.uuid}", normalize_data('build' => data))
    end

    def scheduled(options = {})
      builds = []

      options[:repositories].each do |repository|
        response = get("repos/#{repository}/builds/scheduled")
        json     = JSON.parse(response.body)

        json['response']['builds'].map do |build|
          # really smelly way of converting keys to symbols
          builds << Build.new(symbolize_keys(build).merge(:repository_uuid => repository))
        end
      end

      builds
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

      Trigger.logger.debug "GET #{uri}"

      http(uri).request(request)
    end

    def put(path, data)
      uri     = URI.parse(endpoint(path))
      request = Net::HTTP::Put.new(uri.request_uri)
      request.set_form_data data

      Trigger.logger.debug "PUT #{uri}"

      response = http(uri).request(request)
      raise response.body unless response.code.to_i == 200
      response
    end

    def endpoint(path)
      (Trigger.configuration.use_ssl ? "https://" : "http://") +
        "#{Trigger.configuration.endpoint}/v#{Trigger.configuration.api_version}/#{path}"
    end

    def symbolize_keys(hash)
      Hash[hash.map{ |k, v| [k.to_sym, v] }]
    end

    def normalize_data(hash)
      hash.inject({}) do |target, member|
        key, value = member

        if value.kind_of?(Hash)
          value.each { |key2, value2| target["#{key}[#{key2}]"] = value2.to_s }
        else
          target[key] = value.to_s
        end

        target
      end
    end
  end
end
