# encoding: UTF-8

module Buildbox
  class Observer
    INTERVAL = 3 # feels like a good number

    def initialize(api, build_uuid)
      @api        = api
      @build_uuid = build_uuid

      @queue    = Queue.new
      @results  = {}
      @threads  = {}
    end

    def started(result)
      @results[result.uuid] = result

      update(result.uuid)
    end

    def chunk(result)
      update_on_interval(result.uuid)
    end

    def finished(result)
      # kill off the interval updater
      thread = @threads[result.uuid]
      thread.kill if thread && thread.alive?

      update(result.uuid)
    end

    private

    # every INTERVAL seconds, read from the result and update the server with the output.
    # if we don't do updates every INTERVAL like this, then we end up spamming the server
    # with every chunk we get from the command runner (which ends up being every line), and in the case
    # of a bundle install for example, it may have 100 lines, we end up doing 100 updates to the server.
    def update_on_interval(uuid)
      return if @threads[uuid]

      @threads[uuid] = Thread.new do
        loop do
          update(uuid)
          sleep INTERVAL
        end
      end

      @threads[uuid].abort_on_exception = true
    end

    def update(uuid)
      result       = @results[uuid]
      json         = result.as_json
      json[:state] = json.delete(:finished) ? 'finished' : 'started'

      @api.update_build_result_async(@build_uuid, json.delete(:uuid), json)
    end
  end
end
