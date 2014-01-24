require 'celluloid'
require 'net/http/post/multipart'
require 'mime-types'

module Buildbox
  class Artifact::Poster
    include Celluloid
    include Celluloid::Logger

    def post(api, access_token, build, artifact)
      upload_action = artifact.upload_instructions['action']
      form_data = artifact.upload_instructions['data']

      mime_type = MIME::Types.type_for(artifact.path)[0].to_s

      # Assign the file to upload to the right key in the form
      # data hash.
      file_input_key = upload_action['file_input']
      form_data[file_input_key] = UploadIO.new(artifact.path, mime_type)

      # Let Buildbox know we've started the upload
      api.update_artifact(access_token, build, artifact.remote_id, :state => 'uploading')

      # Do the file upload
      response = begin
                   uri = URI.join(upload_action['url'], upload_action['path'])

                   http = Net::HTTP.new(uri.host, uri.port)
                   http.open_timeout = 64
                   http.read_timeout = 64
                   http.use_ssl = uri.scheme == "https"

                   http.request(Net::HTTP::Post::Multipart.new(uri.path, form_data))
                 rescue => upload_exception
                 end

      if upload_exception
        error "Error uploading #{artifact.basename} with a status of (#{upload_exception.class.name}: #{upload_exception.message})"
        finished_state = 'error'
      else
        info "Finished uploading #{artifact.basename} with a status of #{response.code}"
        finished_state = 'finished'
      end

      api.update_artifact(access_token, build, artifact.remote_id, :state => finished_state)
    end
  end
end
