module Buildbox
  class Result
    def initialize(options)
      @started_at  = options[:started_at]
      @finished_at = options[:finished_at]
      @command     = options[:command]
      @output      = options[:output]
      @exit_status = options[:exit_status]
    end

    def as_json
      { :started_at => @started_at,
        :finished_at => @finished_at,
        :command => @command,
        :output => @output,
        :exit_status => @exit_status }
    end

    def success?
      exit_status == 0
    end
  end
end
