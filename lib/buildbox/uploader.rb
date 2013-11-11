require 'celluloid'

module Buildbox
  class Uploader
    include Celluloid
    include Celluloid::Logger

    def initialize(file, remote_path, api)
      @file        = file
      @remote_path = remote_path
      @api         = api
    end

    def upload
      info "Uploading #{@file} to #{@remote_path}"
    end
  end
end
