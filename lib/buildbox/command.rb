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

      read_io, write_io, pid = nil
      result = Buildbox::Result.new(command)

      # hack: this is so the observer class can raise a started event.
      # instead of having a block passed to this command, we should implement
      # a proper command observer
      yield result

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
              yield result, chunk
            end
            result.output += chunk
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
      result.finished    = true
      result.exit_status = $?.exitstatus

      result
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
