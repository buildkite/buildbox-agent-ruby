module Buildbox
  class Client
    def initialize(options)
      @options  = options
      @interval = 5
    end

    def start
      exit_if_already_running

      Buildbox.logger.info "Starting client..."

      register_client

      begin
        daemonize if @options[:daemon]
        pid_file.save

        loop do
          reload_configuration
          process_build_queue
          wait_for_interval
        end
      rescue => e
        Buildbox.logger.error "#{e.class.name}: #{e.message}"
        e.backtrace.each { |line| Buildbox.logger.error line }

        api.crash(e, :build => @build)
      ensure
        pid_file.delete
      end
    end

    def stop
      Buildbox.logger.info "Stopping client..."

      Process.kill(:KILL, pid_file.delete)
    end

    private

    def daemonize
      if @options[:daemon]
        Process.daemon

        Buildbox.logger = Logger.new(Buildbox.root_path.join("buildbox.log"))
      end
    end

    def register_client
      worker_uuid = Buildbox.configuration.worker_uuid
      response    = api.register(:uuid => worker_uuid, :hostname => `hostname`.chomp)

      Buildbox.configuration.update :worker_uuid, response.payload[:uuid]
    end

    def process_build_queue
      scheduled = api.builds.payload.first

      if scheduled
        # store build in an instance variable so we can report on it in
        # the event of a crash
        @build = Build.new(scheduled)
        Buildbox::Worker.new(@build, api).run
        @build = nil
      end
    end

    def reload_configuration
      Buildbox.configuration.reload
    end

    def wait_for_interval
      Buildbox.logger.debug "Sleeping for #{@interval} seconds"

      sleep(@interval)
    end

    def exit_if_already_running
      if pid_file.exist?
        Buildbox.logger.error "Process (#{pid_file.pid} - #{pid_file.path}) is already running."

        exit 1
      end
    end

    def api
      @api ||= Buildbox::API.new(:api_key => Buildbox.configuration.api_key)
    end

    def pid_file
      @pid_file ||= Buildbox::PidFile.new
    end
  end
end
