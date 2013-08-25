require 'rubygems'
require 'celluloid'

module Buildbox
  class Worker
    include Celluloid::Logger

    def initialize(access_token, api)
      @api          = api
      @access_token = access_token
    end

    def work
      running_builds = scheduled_builds.map do |build|
        Monitor.new(build, @api).async.monitor
        Runner.new(build).future(:start)
      end

      # wait for all the running builds to finish
      running_builds.map(&:value)
    end

    private

    def projects
      @api.worker(:access_token => @access_token, :hostname => hostname).projects
    rescue Buildbox::API::Error
      warn "Worker #{@access_token} doesn't exist"
      [] # return empty array to avoid breakage
    end

    def scheduled_builds
      projects.map do |project|
        @api.scheduled_builds(project)
      end.flatten
    end

    def hostname
      `hostname`.chomp
    end
  end
end
