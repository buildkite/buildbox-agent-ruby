module Buildbox
  class Result
    attr_accessor :started_at, :finished_at, :command, :output, :exit_status

    def initialize(options)
      options.each_pair { |key, value| self.public_send("#{key}=", value) }
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
