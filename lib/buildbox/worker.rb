module Buildbox
  class Worker
    def initialize(access_tokens)
      @access_tokens = access_tokens
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
      @access_tokens.map do |access_token|
        api.worker(:access_token => access_token, :hostname => hostname).projects
      end.flatten
    end

    def hostname
      `hostname`.chomp
    end
  end
end
