module Buildbox
  class Worker
    def initialize(build, api)
      @build = build
      @api   = api
    end

    def run
      results = @build.start do |result|
        update(:result => result.as_json)
      end

      update(:results => results.map(&:as_json))
    end

    private

    def update(results)
      @api.update(@build, results)
    end
  end
end
