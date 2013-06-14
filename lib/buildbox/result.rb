module Buildbox
  class Result
    attr_writer :output
    attr_reader :uuid, :command
    attr_accessor :finished, :exit_status

    def initialize(command)
      @uuid     = SecureRandom.uuid
      @output   = ""
      @finished = false
      @command  = command
    end

    def output
      Buildbox::UTF8.clean(@output).chomp
    end

    def finished?
      finished
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
