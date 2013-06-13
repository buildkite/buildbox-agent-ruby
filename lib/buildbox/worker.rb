module Buildbox
  class Worker
    def initialize(build, api)
      @build = build
      @api   = api
    end

    def run
      results = @build.start do |result|
        update(result)
      end

      update(results)
    end

    private

    def update(results)
      @api.update(@build, :results => [ results ].flatten.map(&:as_json))
    end
  end
end
