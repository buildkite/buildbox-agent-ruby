require 'celluloid'
require 'mime/types'

module Buildbox
  class Uploader
    include Celluloid
    include Celluloid::Logger

    def upload(credentials, absolute_path, &block)
      info "Uploading #{absolute_path}"

      action = credentials[:action]
      data   = credentials[:data]

      connection = Faraday.new(:url => action[:url]) do |faraday|
        faraday.request :multipart

        faraday.options[:timeout] = 60
        faraday.options[:open_timeout] = 60

        faraday.adapter Faraday.default_adapter
      end

      mime_type = MIME::Types.type_for(absolute_path)[0].to_s
      file_input_key = action[:file_input]

      form_data = credentials[:data].to_hash.dup
      form_data[file_input_key] = Faraday::UploadIO.new(absolute_path, mime_type)

      yield("uploading")

      response = connection.post(action[:path], form_data)

      info "Finished uploading #{File.basename(absolute_path)} with a status of #{response.status}"

      yield("finished")
    end
  end
end
