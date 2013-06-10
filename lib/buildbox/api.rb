module Buildbox
  class API
    require 'net/http'
    require 'openssl'
    require 'json'

    def initialize(options)
      @options = options
    end

    def register(data)
      request(:post, "worker", :worker => data)
    end

    def login
      request(:get, "user")
    end

    def update(build, data)
      request(:put, "builds/#{build.uuid}", :build => data)
    end

    def builds(options = {})
      request(:get, "builds").map { |build| Build.new(build) }
    end

    private

    def http(uri)
      Net::HTTP.new(uri.host, uri.port).tap do |http|
        http.use_ssl     = uri.scheme == "https"
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
    end

    def request(method, path, post_data = nil)
      klass   = case method
                when :get  then Net::HTTP::Get
                when :put  then Net::HTTP::Put
                when :post then Net::HTTP::Post
                else raise "No request class defined for `#{method}`"
                end

      uri     = URI.parse(endpoint(path))
      request = klass.new(uri.request_uri)

      if post_data.nil?
        Buildbox.logger.debug "#{method.to_s.upcase} #{uri}"
      else
        normalized_post_data = normalize_data(post_data)
        request.set_form_data normalized_post_data

        Buildbox.logger.debug "#{method.to_s.upcase} #{uri} #{normalized_post_data.inspect}"
      end

      Response.new http(uri).request(request)
    end

    def endpoint(path)
      (Buildbox.configuration.use_ssl ? "https://" : "http://") +
        "#{Buildbox.configuration.endpoint}/v#{Buildbox.configuration.api_version}/#{path}"
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
