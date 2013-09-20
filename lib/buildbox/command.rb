require 'childprocess'
require 'pty'

# Inspiration from:
# https://github.com/mitchellh/vagrant/blob/master/lib/vagrant/util/subprocess.rb

module Buildbox
  class Command
    # The chunk size for reading from subprocess IO.
    READ_CHUNK_SIZE = 4096

    # An error which occurs when the process doesn't end within
    # the given timeout.
    class TimeoutExceeded < StandardError; end

    attr_reader :output, :exit_status

    def self.run(*args, &block)
      command = new(*args, &block)
      command.start(&block)
      command
    end

    def initialize(*args)
      @options   = args.last.is_a?(Hash) ? args.pop : {}
      @arguments = args.dup
      @logger    = Buildbox.logger
    end

    def arguments
      [ *@arguments ].compact.map(&:to_s) # all arguments must be a string
    end

    def process
      @process ||= ChildProcess.build(*arguments)
    end

    def start(&block)
      # Get the timeout, if we have one
      timeout = @options[:timeout]

      # Build the ChildProcess
      @logger.info("Starting process: #{arguments}")

      # fork+exec can be very expensive on *nix platforms. We can minimize the memory
      # by using posix spawn. More info here: https://github.com/rtomayko/posix-spawn
      ChildProcess.posix_spawn = true

      # Set the directory for the process
      process.cwd = File.expand_path(@options[:directory] || Dir.pwd)

      # Create the pipes so we can read the output in real time. PTY
      # isn't avaible on all platforms (heroku) so we just fallback to IO.pipe
      # if it's not presetnt.
      read_pipe, write_pipe = begin
                                PTY.open
                              rescue
                                IO.pipe
                              end

      process.io.stdout     = write_pipe
      process.io.stderr     = write_pipe
      process.duplex        = true

      # Set the environment on the process
      if @options[:environment]
        @options[:environment].each_pair do |key, value|
          process.environment[key] = value
        end
      end

      # Start the process
      process.start

      # Make sure the stdin does not buffer
      process.io.stdin.sync = true

      @logger.info("Process started with PID: #{process.pid} and Group ID: #{Process.getpgid(process.pid)}")

      if RUBY_PLATFORM != "java"
        # On Java, we have to close after. See down the method...
        # Otherwise, we close the writer right here, since we're
        # not on the writing side.
        write_pipe.close
      end

      # Record the start time for timeout purposes
      start_time = Time.now.to_i

      # Track the output as it goes
      output = ""

      @logger.debug("Selecting on IO")
      while true
        results = IO.select([read_pipe], nil, nil, timeout || 0.1) || []
        readers = results[0]

        # Check if we have exceeded our timeout
        raise TimeoutExceeded if timeout && (Time.now.to_i - start_time) > timeout
        # Kill the process and wait a bit for it to disappear
        # Process.kill('KILL', process.pid)
        # Process.waitpid2(process.pid)

        # Check the readers to see if they're ready
        if readers && !readers.empty?
          readers.each do |r|
            # Read from the IO object
            data = read_io(r)

            # We don't need to do anything if the data is empty
            next if data.empty?

            output << cleaned_data = UTF8.clean(data)
            yield cleaned_data if block_given?
          end
        end

        # Break out if the process exited. We have to do this before
        # attempting to write to stdin otherwise we'll get a broken pipe
        # error.
        break if process.exited?
      end

      # Wait for the process to end.
      begin
        remaining = (timeout || 32000) - (Time.now.to_i - start_time)
        remaining = 0 if remaining < 0
        @logger.debug("Waiting for process to exit. Remaining to timeout: #{remaining}")

        process.poll_for_exit(remaining)
      rescue ChildProcess::TimeoutError
        raise TimeoutExceeded
      end

      @logger.debug("Exit status: #{process.exit_code}")

      # Read the final output data, since it is possible we missed a small
      # amount of text between the time we last read data and when the
      # process exited.

      # Read the extra data
      extra_data = read_io(read_pipe)

      # If there's some that we missed
      if extra_data != ""
        output << cleaned_data = UTF8.clean(extra_data)
        yield cleaned_data if block_given?
      end

      if RUBY_PLATFORM == "java"
        # On JRuby, we need to close the writers after the process,
        # for some reason. See https://github.com/mitchellh/vagrant/pull/711
        write_pipe.close
      end

      @output      = output.chomp
      @exit_status = process.exit_code
    end

    private

    # Reads data from an IO object while it can, returning the data it reads.
    # When it encounters a case when it can't read anymore, it returns the
    # data.
    #
    # @return [String]
    def read_io(io)
      data = ""

      while true
        begin
          if Platform.windows?
            # Windows doesn't support non-blocking reads on
            # file descriptors or pipes so we have to get
            # a bit more creative.

            # Check if data is actually ready on this IO device.
            # We have to do this since `readpartial` will actually block
            # until data is available, which can cause blocking forever
            # in some cases.
            results = IO.select([io], nil, nil, 0.1)
            break if !results || results[0].empty?

            # Read!
            data << io.readpartial(READ_CHUNK_SIZE)
          else
            # Do a simple non-blocking read on the IO object
            data << io.read_nonblock(READ_CHUNK_SIZE)
          end
        rescue Exception => e
          # The catch-all rescue here is to support multiple Ruby versions,
          # since we use some Ruby 1.9 specific exceptions.

          breakable = false

          # EOFError from OSX, EIO is raised by ubuntu
          if e.is_a?(EOFError) || e.is_a?(Errno::EIO)
            # An `EOFError` means this IO object is done!
            breakable = true
          elsif defined?(IO::WaitReadable) && e.is_a?(IO::WaitReadable)
            # IO::WaitReadable is only available on Ruby 1.9+

            # An IO::WaitReadable means there may be more IO but this
            # IO object is not ready to be read from yet. No problem,
            # we read as much as we can, so we break.
            breakable = true
          elsif e.is_a?(Errno::EAGAIN) || e.is_a?(Errno::EWOULDBLOCK)
            # Otherwise, we just look for the EAGAIN error which should be
            # all that IO::WaitReadable does in Ruby 1.9.
            breakable = true
          end

          # Break out if we're supposed to. Otherwise re-raise the error
          # because it is a real problem.
          break if breakable
          raise
        end
      end

      data
    end
  end
end
