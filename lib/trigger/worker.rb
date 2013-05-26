module Trigger
  class Worker
    def initialize(build, api)
      @build = build
      @api   = api
    end

    def run
      update(:started_at => Time.now)

      chunks = ""
      result = @build.start do |chunk|
        update(:output => chunks += chunk)
      end

      update(:output => result.output, :finished_at => Time.now)
    end

    private

    def update(data)
      @api.update(@build, data)
    end
  end
end
