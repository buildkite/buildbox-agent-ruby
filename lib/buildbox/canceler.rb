require 'celluloid'
require 'timeout'

module Buildbox
  class Canceler
    include Celluloid

    def initialize(build)
      @build = build
    end

    def cancel
      @build.cancel_started = true

      # Store all the child processes before we stop so we can reap them after.
      # A new process may start up between this and the process stopping,
      # but that should be OK for now.
      child_processes = process_map[@build.process.pid]

      # Stop the process
      Buildbox.logger.info "Cancelling build #{@build.namespace}/#{@build.id} with PID #{@build.process.pid}"
      @build.process.stop

      begin
        @build.process.wait
      rescue Errno::ECHILD
        # Wow! That finished quickly...
      end

      kill_processes(child_processes)
    end

    private

    def kill_processes(processes)
      processes.each do |pid|
        Buildbox.logger.debug "Sending a TERM signal to child process with PID #{pid}"

        begin
          Process.kill("TERM", pid)

          # If the child process doesn't die within 5 seconds, try a more
          # forceful kill command
          begin
            Timeout.timeout(5) do
              Process.wait
            end
          rescue Timeout::Error
            Buildbox.logger.debug "Sending a KILL signal to child process with PID #{pid}"

            Process.kill("KILL", pid)
          rescue Errno::ECHILD
            # Killed already
          end
        rescue Errno::ESRCH
          # No such process
        end
      end
    end

    # Generates a map of parent process and child processes. This method
    # will currently only work on unix.
    def process_map
      output    = `ps -eo ppid,pid`
      processes = {}

      output.split("\n").each do |line|
        if result = line.match(/(\d+)\s(\d+)/)
          parent = result[1].to_i
          child  = result[2].to_i

          processes[parent] ||= []
          processes[parent] << child
        end
      end

      processes
    end
  end
end
