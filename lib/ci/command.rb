# The CI::Command module was stolen from Integrity
# https://github.com/integrity/integrity/blob/master/lib/integrity/command_runner.rb

module CI
  class Command
    class Error < StandardError; end
    def initialize(logger, build_output_interval=nil)
      @logger = logger
      @build_output_interval = build_output_interval || 5
    end

    def cd(dir)
      @dir = dir
      yield self
    ensure
      @dir = nil
    end

    def run(command)
      @logger.debug(command)

      output = ""
      rd, wr = IO.pipe

      if pid = fork
        # parent
        wr.close
        while true
          fds, = IO.select([rd], nil, nil, @build_output_interval)
          if fds
            # should have some data to read
            begin
              chunk = rd.read_nonblock(10240)
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
        rd.close
        Process.waitpid(pid)
      else
        # child
        rd.close
        STDOUT.reopen(wr)
        wr.close
        STDERR.reopen(STDOUT)
        if @dir
          Dir.chdir(@dir)
        end
        exec(command)
      end

      # output may be invalid UTF-8, as it is produced by the build command.
      # output = CI::UTF8.clean(output)

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
