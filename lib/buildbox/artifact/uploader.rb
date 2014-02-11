require 'celluloid'
require 'mime/types'

module Buildbox
  class Artifact::Uploader
    include Celluloid
    include Celluloid::Logger

    def initialize(api, access_token, build, artifacts)
      @api = api
      @access_token = access_token
      @build = build
      @artifacts = artifacts
    end

    def prepare_and_upload
      info "Preparing #{@artifacts.count} artifacts for upload"

      responses = @api.create_artifacts(@access_token, @build, @artifacts)
      responses.each do |response|
        artifact = @artifacts.find { |artifact| artifact.id == response['id'] }

        artifact.remote_id = response['artifact']['id']
        artifact.upload_instructions = response['artifact']['uploader']
      end

      @artifacts.each do |artifact|
        Celluloid::Actor[:artifact_poster_pool].async.post(@api, @access_token, @build, artifact)
      end
    end
  end
end
