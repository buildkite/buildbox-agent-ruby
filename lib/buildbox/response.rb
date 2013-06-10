module Buildbox
  class Response < Hash
    def initialize(response)
      @response = response

      raise @response.inspect if !success? || !json?
      json = JSON.parse(@response.body)

      replace symbolize_keys(json)
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
