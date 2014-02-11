module Buildbox
  module Model
    def initialize(attributes = {})
      if attributes.kind_of?(Hash)
        self.attributes = attributes
      end
    end

    def attributes=(attributes)
      attributes.each_pair do |key, value|
        instance_variable_set("@#{key}", value)
      end
    end
  end
end
