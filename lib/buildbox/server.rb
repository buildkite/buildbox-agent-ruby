module Buildbox
  class Server
    def start
      loop do
        access_tokens.each do |access_token|
          api.worker(:access_token => access_token, :hostname => `hostname`.chomp).projects.each do |project|
            running_builds = api.scheduled_builds(project).map do |build|
              Monitor.new(build, api).async.monitor
              Builder.new(build).future(:start)
            end

            # wait for all the running builds to finish
            running_builds.map(&:value)

            sleep 5
          end
        end
      end
    end

    private

    def api
      @api ||= Api.new
    end

    def access_tokens
      Buildbox.config.worker_access_tokens
    end
  end
end
