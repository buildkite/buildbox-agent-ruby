module Buildbox
  class Worker
    def initialize(build, api)
      @build = build
      @api   = api
    end

    def run
      @build.start :partial_result => method(:partial_result),
                   :finished_result => method(:finished_result),
                   :finished_build => method(:finished_build)

      # update(:results => results.map(&:json))
    end

    private

    def partial_result(message)
      p message
    end

    def finished_result
    end

    def finished_build
    end

    def update(data)
      # @api.update(@build, data)
    end
  end
end
