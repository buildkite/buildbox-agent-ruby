require 'celluloid'
require 'mime/types'

module Buildbox
  class Uploader
    include Celluloid
    include Celluloid::Logger

    def upload(api, access_token, current_build, relative_path, absolute_path)
      info "Uploading #{absolute_path}"

      artifact = api.create_artifact(access_token, current_build,
                                     :path => relative_path,
                                     :file_size => File.size(absolute_path))


      upload_action = artifact[:uploader][:action]
      form_data     = artifact[:uploader][:data].to_hash.dup

      connection = Faraday.new(:url => upload_action[:url]) do |faraday|
        faraday.request :multipart

        faraday.response :raise_error

        faraday.options[:timeout] = 60
        faraday.options[:open_timeout] = 60

        faraday.adapter Faraday.default_adapter
      end

      mime_type = MIME::Types.type_for(absolute_path)[0].to_s

      file_input_key = upload_action[:file_input]
      form_data[file_input_key] = Faraday::UploadIO.new(absolute_path, mime_type)

      api.update_artifact(access_token, current_build, artifact[:id], :state => 'uploading')

      upload_exception = nil
      response         = nil

      begin
        response = connection.post(upload_action[:path], form_data)
      rescue => e
        upload_exception = e
      end

      if upload_exception
        error "Error uploading #{File.basename(absolute_path)} with a status of (#{upload_exception.class.name}: #{upload_exception.message})"
        finished_state = 'error'
      else
        info "Finished uploading #{File.basename(absolute_path)} with a status of #{response.status}"
        finished_state = 'finished'
      end

      api.update_artifact(access_token, current_build, artifact[:id], :state => finished_state)
    end
  end
end
