module CI
  class Command
    require 'pty'

    class Error < StandardError; end
    def initialize(logger, build_output_interval=nil)
      @logger = logger
      @build_output_interval = build_output_interval || 5
    end

    def cd(dir)
      dir = File.expand_path(dir)

      Dir.chdir(dir) do
        yield self
      end
    end

    def run(command)
      @logger.debug(command)
      output = ""

      begin
        # spawn the process in a pseudo terminal so colors out outputted
        read_io, write_io, pid = PTY.spawn(command)
      rescue Errno::ENOENT => e
        return CI::Result.new(false, e.message)
      end

      write_io.close

      while true
        fds, = IO.select([read_io], nil, nil, @build_output_interval)
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
        @logger.error(result.output.inspect)
        raise Error, "Failed to run '#{command}': #{result.output}"
      end

      result
    end
  end
end
