module CI
  class Client
    def initialize(options)
      @options  = options
    end

    def start
      CI.logger.info "Starting CI Client..."

      exit_if_already_running
      Process.daemon if @options[:daemon]

      set_program_name
      trap_int_signals
      pid_file.save

      loop do
        process_build_queue

        sleep 5
      end
    ensure
      pid_file.delete
    end

    def stop
      Process.kill(:KILL, pid_file.delete)
    end

    private

    def set_program_name
      $PROGRAM_NAME = "ci"
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

    def trap_int_signals
      Signal.trap(:INT) { stop }
    end

    def api
      @api ||= CI::API.new
    end

    def pid_file
      @pid_file ||= CI::PidFile.new
    end
  end
end
