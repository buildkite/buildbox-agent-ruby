# encoding: UTF-8

module Buildbox
  class Worker
    def process
      if scheduled = api.builds.payload.first
        start Build.new(scheduled)
      end
    end

    private

    def start(build)
      api.update_build_state(build.uuid, 'started')
      build.start Buildbox::Observer.new(api, build.uuid)
      api.update_build_state_async(build.uuid, 'finished')
    end

    def api
      @api ||= Buildbox::API.new(:api_key => Buildbox.configuration.api_key)
    end
  end
end
