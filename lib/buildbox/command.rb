require 'pty'

module Buildbox
  class Command
    class Result < Struct.new(:output, :exit_status)
    end

    def self.run(command, options = {}, &block)
      new(command, options).run(&block)
    end

    def initialize(command, options = {})
      @command       = command
      @directory     = options[:directory] || "."
      @read_interval = options[:read_interval] || 5
    end

    def run(&block)
      output = ""
      read_io, write_io, pid = nil

      # spawn the process in a pseudo terminal so colors out outputted
      read_io, write_io, pid = PTY.spawn("cd #{expanded_directory} && #{@command}")

      # we don't need to write to the spawned io
      write_io.close

      loop do
        fds, = IO.select([read_io], nil, nil, read_interval)
        if fds
          # should have some data to read
          begin
            chunk         = read_io.read_nonblock(10240)
            cleaned_chunk = UTF8.clean(chunk)

            output << chunk
            yield cleaned_chunk if block_given?
          rescue Errno::EAGAIN, Errno::EWOULDBLOCK
            # do select again
          rescue EOFError, Errno::EIO # EOFError from OSX, EIO is raised by ubuntu
            break
          end
        end
        # if fds are empty, timeout expired - run another iteration
      end

      # we're done reading, yay!
      read_io.close

      # just wait until its finally finished closing
      Process.waitpid(pid)

      # the final result!
      Result.new(output.chomp, $?.exitstatus)
    end

    private

    def expanded_directory
      File.expand_path(@directory)
    end

    def read_interval
      @read_interval
    end
  end
end
