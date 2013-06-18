# encoding: UTF-8

module Buildbox
  class Response
    attr_reader :payload

    def initialize(response)
      @response = response

      Buildbox.logger.debug "Status: #{status_code}"
      Buildbox.logger.debug "Content Type: #{content_type}"
      Buildbox.logger.debug @response.body

      raise "API Response Error: #{@response.code} #{@response.body}" unless success?

      if json?
        json = JSON.parse(@response.body)

        if json.kind_of?(Array)
          @payload = json.map { |item| symbolize_keys(item) }
        else
          @payload = symbolize_keys(json)
        end
      end
    end

    def success?
      status_code == 200
    end

    private

    def status_code
      @response.code.to_i
    end

    def content_type
      @response['content-type']
    end

    def json?
      content_type =~ /json/
    end

    def symbolize_keys(hash)
      hash.inject({}) do |result, item|
        key, value = item
        new_key   = case key
                    when String then key.to_sym
                    else key
                    end
        new_value = case value
                    when Hash then symbolize_keys(value)
                    else value
                    end
        result[new_key] = new_value
        result
      end
    end
  end
end
