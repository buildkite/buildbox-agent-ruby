module Buildbox
  class Command
    require 'pty'

    class Error < StandardError; end

    def initialize(path = nil, read_interval = nil)
      @path          = path || "."
      @read_interval = read_interval || 5
    end

    def run(command)
      Buildbox.logger.debug(command)

      started_at = Time.now
      output = ""
      read_io, write_io, pid = nil

      begin
        dir = File.expand_path(@path)

        # spawn the process in a pseudo terminal so colors out outputted
        read_io, write_io, pid = PTY.spawn("cd #{dir} && #{command}")
      rescue Errno::ENOENT => e
        return Buildbox::Result.new(false, e.message)
      end

      write_io.close

      loop do
        fds, = IO.select([read_io], nil, nil, @read_interval)
        if fds
          # should have some data to read
          begin
            chunk = read_io.read_nonblock(10240)
            if block_given?
              yield chunk
            end
            output += chunk
          rescue Errno::EAGAIN, Errno::EWOULDBLOCK
            # do select again
          rescue EOFError, Errno::EIO # EOFError from OSX, EIO is raised by ubuntu
            break
          end
        end
        # if fds are empty, timeout expired - run another iteration
      end

      read_io.close
      Process.waitpid(pid)

      # output may be invalid UTF-8, as it is produced by the build command.
      output = Buildbox::UTF8.clean(output)

      Buildbox::Result.new(:started_at => started_at,
                           :finished_at => Time.now,
                           :command => command,
                           :output => output.chomp,
                           :exit_status => $?.exitstatus)
    end

    def run!(command)
      result = run(command)

      unless result.success?
        raise Error, "Failed to run '#{command}': #{result.output}"
      end

      result
    end
  end
end
