module Trigger
  class Configuration
    attr_accessor :endpoint
    attr_accessor :use_ssl
    attr_accessor :api_version

    def initialize
      @use_ssl      = true
      @endpoint     = 'api.triggerci.com'
      @api_version  = 1
    end
  end
end
