module CI
  class Client
    def initialize(options)
      @options      = options
      @pidfile_path = CI.root_path.join("ci.pid")
    end

    def start
      CI.logger.info "Starting CI Client..."

      exit_if_already_running
      daemonize if @options[:daemon]

      trap_int_signals
      write_pid_to_disk

      loop do
        p 'watching...'

        sleep 5
      end
    end

    def stop
      shutdown_process_from_pid
      remove_pid_from_disk
    end

    private

    def shutdown_process_from_pid
      pid = File.readlines(@pidfile_path).first.to_i

      Process.kill(:TERM, pid)
    end

    def exit_if_already_running
      if File.exist?(@pidfile_path)
        CI.logger.error "CI is already running. Found a pidfile at `#{@pidfile_path}`"

        exit 1
      end
    end

    def trap_int_signals
      Signal.trap(:INT) do
        stop
      end
    end

    def daemonize
      Process.daemon
    end

    def remove_pid_from_disk
      File.delete(@pidfile_path)
    end

    def write_pid_to_disk
      File.open(@pidfile_path, 'w+') { |file| file.write(Process.pid.to_s) }
    end
  end
end
