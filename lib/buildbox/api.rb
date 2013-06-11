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

      request(:post, "crashes", :crash => payload)
    end

    def register(payload)
      request(:post, "workers", :worker => payload)
    end

    def login
      request(:get, "user")
    end

    def update(build, payload)
      request(:put, "workers/#{worker_uuid}/builds/#{build.uuid}", :build => payload)
    end

    def builds(options = {})
      request(:get, "workers/#{worker_uuid}/builds")
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
      request = klass.new(uri.request_uri)

      if payload.nil?
        Buildbox.logger.debug "#{method.to_s.upcase} #{uri}"
      else
        normalized_payload = normalize_payload(payload)
        request.set_form_data normalized_payload

        Buildbox.logger.debug "#{method.to_s.upcase} #{uri} #{normalized_payload.inspect}"
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

    # This is the worst method I've ever written, sorry.
    # { :foo => { :bar => { :bang => "yolo" } } } => { "foo[bar][bang]" => "yolo" }
    def normalize_payload(hash)
      hash.inject({}) do |target, member|
        key, value = member

        if value.kind_of?(Hash)
          value.each do |key2, value2|
            if value2.kind_of?(Hash)
              normalize_payload(value2).each_pair do |key3, value3|
                target["#{key}[#{key2}][#{key3}]"] = value3.to_s
              end
            else
              target["#{key}[#{key2}]"] = value2.to_s
            end
          end
        else
          target[key] = value.to_s
        end

        target
      end
    end
  end
end
