require 'celluloid'

module Buildbox
  class Uploader
    include Celluloid
    include Celluloid::Logger

    def upload(credentials, absolute_path)
      info "Uploading #{absolute_path} with #{credentials}"
    end
  end
end
