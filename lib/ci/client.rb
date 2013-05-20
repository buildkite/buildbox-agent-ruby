module CI
  class Client
    def initialize(options)
      @options  = options
      @interval = 5
    end

    def start
      CI.logger.info "Starting CI Client..."

      exit_if_already_running
      daemonize if @options[:daemon]
      pid_file.save

      loop do
        process_build_queue && sleep(@interval)
      end
    ensure
      pid_file.delete
    end

    def stop
      CI.logger.info "Stopping CI Client..."

      Process.kill(:KILL, pid_file.delete)
    end

    private

    def daemonize
      Process.daemon if @options[:daemon]
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
