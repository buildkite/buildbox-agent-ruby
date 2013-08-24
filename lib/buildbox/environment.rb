module Buildbox
  class Environment
    def initialize(environment)
      @environment = environment
    end

    def any?
      @environment && @environment.keys.length > 0
    end

    def to_s
      @environment.to_a.map do |key, value|
        %{#{key}=#{value.inspect}}
      end.join(" ")
    end
  end
end
