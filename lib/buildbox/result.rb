module Buildbox
  class Result
    attr_accessor :uuid, :command, :output, :exit_status

    def initialize(options)
      options.each_pair { |key, value| self.public_send("#{key}=", value) }
    end

    def success?
      exit_status == 0
    end

    def as_json
      { :uuid        => @uuid,
        :command     => @command,
        :output      => @output,
        :exit_status => @exit_status }
    end
  end
end
