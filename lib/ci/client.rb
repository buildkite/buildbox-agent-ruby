module CI
  class Client
    def initialize(options)
      @options  = options
      @interval = 5
    end

    def start
      exit_if_already_running

      CI.logger.info "Starting client..."

      begin
        daemonize if @options[:daemon]
        pid_file.save

        loop do
          process_build_queue

          CI.logger.info "Sleeping for #{@interval} seconds"
          sleep(@interval)
        end
      ensure
        pid_file.delete
      end
    end

    def stop
      CI.logger.info "Stopping client..."

      Process.kill(:KILL, pid_file.delete)
    end

    private

    def daemonize
      if @options[:daemon]
        Process.daemon

        CI.logger = Logger.new(CI.root_path.join("ci.log"))
      end
    end

    def process_build_queue
      build = api.queue.first

      CI::Worker.new(build, api).run if build
    end

    def exit_if_already_running
      if pid_file.exist?
        CI.logger.error "Process (#{pid_file.pid} - #{pid_file.path}) is already running."

        exit 1
      end
    end

    def api
      @api ||= CI::API.new
    end

    def pid_file
      @pid_file ||= CI::PidFile.new
    end
  end
end
