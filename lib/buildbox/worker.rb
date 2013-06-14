module Buildbox
  class Worker
    def initialize(build, api)
      @build = build
      @api   = api
    end

    def run
      update(@build, :started_at => Time.now)

      results = @build.start do |result|
        update(:results =>  [ result.as_json ])
      end

      update(:finished_at => Time.now, :results => results.map(&:as_json))
    end

    private

    def update(results)
      @api.update(@build, :results => [ results ].flatten.map(&:as_json))
    end
  end
end
