module Buildbox
  class Queue
    def process
      if scheduled = api.builds.payload.first
        start Build.new(scheduled)
      end
    end

    private

    def start(build)
      api.update_build_state(build.uuid, 'started')

      build.start do |result|
        json         = result.as_json
        json[:state] = json.delete(:finished) ? 'finished' : 'started'

        api.update_build_result_async(build.uuid, json.delete(:uuid), json)
      end

      api.update_build_state_async(build.uuid, 'finished')
    end

    def api
      @api ||= Buildbox::API.new(:api_key => Buildbox.configuration.api_key)
    end
  end
end
