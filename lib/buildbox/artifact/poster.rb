require 'celluloid'

module Buildbox
  class Artifact::Poster
    include Celluloid
    include Celluloid::Logger

    def post(api, access_token, build, artifact)
      upload_action = artifact.upload_instructions['action']
      form_data     = artifact.upload_instructions['data'].to_hash.dup

      connection = Faraday.new(:url => upload_action['url']) do |faraday|
        faraday.request :multipart

        faraday.response :raise_error

        faraday.options[:timeout] = 60
        faraday.options[:open_timeout] = 60

        faraday.adapter Faraday.default_adapter
      end

      mime_type = MIME::Types.type_for(artifact.path)[0].to_s

      file_input_key = upload_action['file_input']
      form_data[file_input_key] = Faraday::UploadIO.new(artifact.path, mime_type)

      api.update_artifact(access_token, build, artifact.remote_id, :state => 'uploading')

      upload_exception = nil
      response         = nil

      begin
        response = connection.post(upload_action['path'], form_data)
      rescue => e
        upload_exception = e
      end

      if upload_exception
        error "Error uploading #{artifact.basename} with a status of (#{upload_exception.class.name}: #{upload_exception.message})"
        finished_state = 'error'
      else
        info "Finished uploading #{artifact.basename} with a status of #{response.status}"
        finished_state = 'finished'
      end

      api.update_artifact(access_token, build, artifact.remote_id, :state => finished_state)
    end
  end
end
