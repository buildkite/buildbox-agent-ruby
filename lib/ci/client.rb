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
      pid = pid_file.read
      pid_file.delete

      Process.kill(:KILL, pid)
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
        CI.logger.error "CI is already running. Found a pidfile at `#{@pidfile_path}`"

        exit 1
      end
    end

    def trap_int_signals
      Signal.trap(:INT) do
        stop
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
