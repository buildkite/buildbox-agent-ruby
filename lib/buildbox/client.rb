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
        register_quit_signal
        pid_file.save

        loop do
          reload_configuration
          Buildbox::Worker.new.process

          if @shutdown
            stop
          else
            wait_for_interval
          end
        end
      rescue => e
        Buildbox.logger.error "#{e.class.name}: #{e.message}"
        e.backtrace.each { |line| Buildbox.logger.error line }

        api.crash(e)
      ensure
        pid_file.delete
      end
    end

    def stop
      Buildbox.logger.info "Stopping client..."

      # if the pid is the current process, just exit
      if $$ == pid_file.pid
        exit 0
      else
        Process.kill(:KILL, pid_file.delete)
      end
    end

    private

    def daemonize
      if @options[:daemon]
        Process.daemon

        Buildbox.logger = Logger.new(Buildbox.root_path.join("buildbox.log"))
      end
    end

    def register_quit_signal
      trap(:QUIT) do
        @shutdown = true
      end
    end

    def register_client
      worker_uuid = Buildbox.configuration.worker_uuid
      response    = api.register(:uuid => worker_uuid, :hostname => `hostname`.chomp)

      Buildbox.configuration.update :worker_uuid, response.payload[:uuid]
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

    def worker
    end

    def api
      @api ||= Buildbox::API.new(:api_key => Buildbox.configuration.api_key)
    end

    def pid_file
      @pid_file ||= Buildbox::PidFile.new
    end
  end
end
