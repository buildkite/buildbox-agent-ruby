require 'rubygems'
require 'hashie/mash'

module Buildbox
  class Build < Hashie::Mash
    def success?
      exit_status == 0
    end

    def started?
      !started_at.nil?
    end

    def finished?
      !finished_at.nil?
    end

    def namespace
      "#{project.team.id}/#{project.id}"
    end
  end
end
