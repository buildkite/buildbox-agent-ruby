require 'rubygems'
require 'hashie/mash'

module Buildbox
  class Build < Hashie::Mash
    class Status
      STARTED  = 'started'
      FINISHED = 'finished'
    end

    class Part < Hashie::Mash
      def success?
        exit_status == 0
      end
    end

    attr_reader :parts

    def initialize(*args)
      @parts = []
      super(*args)
    end

    def success?
      !@parts.empty? && @parts.last.success?
    end

    def started?
      status == Status::STARTED
    end

    def finished?
      status == Status::FINISHED
    end

    def namespace
      raise "Missing project id" unless project.id
      raise "Missing team id" unless project.team.id

      "#{project.team.id}/#{project.id}"
    end
  end
end
