module Buildbox
  class Response
    attr_reader :payload

    def initialize(response)
      @response = response

      raise "API Error: #{@response.code} #{@response.body}" if !success? || !json?

      json = JSON.parse(@response.body)

      if json.kind_of?(Array)
        @payload = json.map { |item| symbolize_keys(item) }
      else
        @payload = symbolize_keys(json)
      end
    end

    def success?
      @response.code.to_i == 200
    end

    private

    def json?
      @response['content-type'] =~ /json/
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
