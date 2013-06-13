module Buildbox
  class Result
    attr_accessor :uuid, :started_at, :finished_at, :command, :output, :exit_status

    def initialize(options)
      options.each_pair { |key, value| self.public_send("#{key}=", value) }
    end

    def success?
      exit_status == 0
    end

    def as_json
      { :uuid        => @uuid,
        :started_at  => @started_at,
        :finished_at => @finished_at,
        :command     => @command,
        :output      => @output,
        :exit_status => @exit_status }.delete_if { |k, v| v.nil? }
    end
  end
end
