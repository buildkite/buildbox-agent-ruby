module CI
  class Command
    require 'pty'

    class Error < StandardError; end

    def initialize(path = nil, read_interval = nil)
      @path          = path || "."
      @read_interval = read_interval || 5
    end

    def run(command)
      # CI.logger.debug(command)
      output = ""
      read_io, write_io, pid = nil

      begin
        dir = File.expand_path(@path)

        # spawn the process in a pseudo terminal so colors out outputted
        read_io, write_io, pid = PTY.spawn("cd #{dir} && #{command}")
      rescue Errno::ENOENT => e
        return CI::Result.new(false, e.message)
      end

      write_io.close

      while true
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
          rescue EOFError
            break
          end
        end
        # if fds are empty, timeout expired - run another iteration
      end

      read_io.close
      Process.waitpid(pid)

      # output may be invalid UTF-8, as it is produced by the build command.
      output = CI::UTF8.clean(output)

      CI::Result.new($?.success?, output.chomp)
    end

    def run!(command)
      result = run(command)

      unless result.success
        # CI.logger.error(result.output.inspect)
        raise Error, "Failed to run '#{command}': #{result.output}"
      end

      result
    end
  end
end
