require 'rubygems'
require 'hashie/mash'

module Buildbox
  class Build < Hashie::Mash
    def initialize(*args)
      self.output = ""
      super(*args)
    end

    def success?
      exit_status == 0
    end

    def started?
      output.kind_of?(String) && output.length > 0
    end

    def finished?
      exit_status != nil
    end
  end
end
