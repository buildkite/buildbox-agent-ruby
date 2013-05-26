module Trigger
  class Client
    def initialize(options)
      @options  = options
      @interval = 5
    end

    def start
      exit_if_already_running

      Trigger.logger.info "Starting client..."

      begin
        daemonize if @options[:daemon]
        pid_file.save

        loop do
          process_build_queue

          Trigger.logger.info "Sleeping for #{@interval} seconds"
          sleep(@interval)
        end
      ensure
        pid_file.delete
      end
    end

    def stop
      Trigger.logger.info "Stopping client..."

      Process.kill(:KILL, pid_file.delete)
    end

    private

    def daemonize
      if @options[:daemon]
        Process.daemon

        Trigger.logger = Logger.new(Trigger.root_path.join("ci.log"))
      end
    end

    def process_build_queue
      build = api.scheduled.first

      Trigger::Worker.new(build, api).run if build
    end

    def exit_if_already_running
      if pid_file.exist?
        Trigger.logger.error "Process (#{pid_file.pid} - #{pid_file.path}) is already running."

        exit 1
      end
    end

    def api
      @api ||= Trigger::API.new
    end

    def pid_file
      @pid_file ||= Trigger::PidFile.new
    end
  end
end
