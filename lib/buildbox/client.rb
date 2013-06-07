module Buildbox
  class Client
    def initialize(options)
      @options  = options
      @interval = 5
    end

    def start
      exit_if_already_running

      Buildbox.logger.info "Starting client..."

      begin
        daemonize if @options[:daemon]
        pid_file.save

        loop do
          reload_configuration
          process_build_queue
          wait_for_interval
        end
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

        Buildbox.logger = Logger.new(Buildbox.root_path.join("ci.log"))
      end
    end


    def process_build_queue
      build = api.scheduled(:repositories => Buildbox.configuration.repositories).first

      Buildbox::Worker.new(build, api).run if build
    end

    def reload_configuration
      Buildbox.logger.info "Reloading configuration"

      Buildbox.configuration.reload
    end

    def wait_for_interval
      Buildbox.logger.info "Sleeping for #{@interval} seconds"

      sleep(@interval)
    end

    def exit_if_already_running
      if pid_file.exist?
        Buildbox.logger.error "Process (#{pid_file.pid} - #{pid_file.path}) is already running."

        exit 1
      end
    end

    def api
      @api ||= Buildbox::API.new
    end

    def pid_file
      @pid_file ||= Buildbox::PidFile.new
    end
  end
end
