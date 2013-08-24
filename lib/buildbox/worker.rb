module Buildbox
  class Worker
    def initialize(access_token)
      @access_token = access_token
    end

    def start
      loop do
        projects.each do |project|
          running_builds = api.scheduled_builds(project).map do |build|
            Monitor.new(build, api).async.monitor
            Runner.new(build).future(:start)
          end

          # wait for all the running builds to finish
          running_builds.map(&:value)

          sleep 5
        end
      end
    end

    private

    def api
      @api ||= Buildbox::API.new
    end

    def projects
      api.worker(:access_token => @access_token, :hostname => hostname).projects
    end

    def hostname
      `hostname`.chomp
    end
  end
end
