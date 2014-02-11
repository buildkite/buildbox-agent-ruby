require 'net/http'
require 'net/https'
require 'oj'

module Buildbox
  class Connection
    class Error < StandardError; end
    class NotFoundError < Error; end
    class UnexpectedResponseError < Error; end

    def initialize(logger, endpoint, ca_file)
      @logger = logger
      @endpoint = URI.parse(endpoint)
      @ca_file = ca_file
    end

    def request(method, path, body = nil)
      # Poor mans URI concatination
      path = File.join(@endpoint.request_uri, path)
      attempts = 3

      begin
        @logger.debug "#{method} #{path}"

        response = case method
                   when :get
                     http.get(path)
                   when :post
                     http.post(path, dump_request_json(body), headers)
                   when :put
                     http.put(path, dump_request_json(body), headers)
                   end

        handle_response(response)
      rescue => e
        if (attempts -= 1).zero?
          raise e
        else
          retry
        end
      end
    end

    private

    def headers
      { "Content-Type" => "application/json" }
    end

    def dump_request_json(json)
      # Compact ensures symbols get turned into strings
      Oj.dump(json, :mode => :compat)
    end

    def parse_response_json(response)
      if response.content_type == "application/json"
        Oj.load(response.body)
      else
        raise UnexpectedResponseError.new(response.body[0..100])
      end
    end

    def handle_response(response)
      case response.code.to_i
      when 200...300
        parse_response_json(response)
      when 404
        raise NotFoundError.new(parse_response_json(response))
      else
        raise UnexpectedResponseError.new(response.body)
      end
    end

    def http
      http = Net::HTTP.new(@endpoint.host, @endpoint.port)
      http.open_timeout = 64
      http.read_timeout = 64

      if @endpoint.scheme == "https"
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      end

      http.ca_file = @ca_file
      http
    end
  end
end
