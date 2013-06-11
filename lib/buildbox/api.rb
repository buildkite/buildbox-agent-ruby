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

    # { :foo => { :bar => { :bang => "yolo" } } } => { "foo[bar][bang]" => "yolo" }
    def normalize_payload(params, key=nil)
      params = flatten_keys(params) if params.is_a?(Hash)
      result = {}
      params.each do |k,v|
        case v
        when Hash
          result[k.to_s] = normalize_params(v)
        when Array
          v.each_with_index do |val,i|
            result["#{k.to_s}[#{i}]"] = val.to_s
          end
        else
          result[k.to_s] = v.to_s
        end
      end
      result
    end

    def flatten_keys(hash, newhash={}, keys=nil)
      hash.each do |k, v|
        k = k.to_s
        keys2 = keys ? keys+"[#{k}]" : k
        if v.is_a?(Hash)
          flatten_keys(v, newhash, keys2)
        else
          newhash[keys2] = v
        end
      end
      newhash
    end
  end
end
