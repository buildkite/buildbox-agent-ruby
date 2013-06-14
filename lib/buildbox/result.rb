module Buildbox
  class Result
    require 'securerandom'

    attr_reader :uuid, :command
    attr_accessor :output, :finished, :exit_status

    def initialize(command)
      @uuid     = SecureRandom.uuid
      @output   = ""
      @finished = false
      @command  = command
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
        :output      => clean_output,
        :exit_status => @exit_status }
    end

    private

    def clean_output
      Buildbox::UTF8.clean(@output).chomp
    end
  end
end
