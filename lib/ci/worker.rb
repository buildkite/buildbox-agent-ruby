module CI
  class Worker
    def initialize(build, api)
      @build = build
      @api   = api
    end

    def run
      result = @build.start
      p result.output
      p result.success
    end
  end
end
