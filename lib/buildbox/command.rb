require 'childprocess'
require 'pty'

module Buildbox
  class Command
    class Result < Struct.new(:output, :exit_status)
    end

    def self.command(command, options = {}, &block)
      new(command, options).start(&block)
    end

    def self.script(script, options = {}, &block)
      new(script, options).start(&block)
    end

    def initialize(arguments, options = {})
      @arguments     = arguments
      @environment   = options[:environment] || {}
      @directory     = options[:directory] || "."
    end

    def start(&block)
      read_io, write_io = IO.pipe

      arguments         = [ *runner, *@arguments ].compact.map(&:to_s) # all arguments must be a string
      process           = ChildProcess.build(*arguments)
      process.cwd       = expanded_directory
      process.io.stdout = process.io.stderr = write_io

      @environment.each_pair do |key, value|
        process.environment[key] = value
      end

      process.start
      write_io.close

      output = ""
      begin
        loop do
          chunk         = read_io.readpartial(10240)
          cleaned_chunk = UTF8.clean(chunk)

          output << chunk
          yield cleaned_chunk if block_given?
        end
      rescue EOFError
      end

      process.wait

      # the final result!
      Result.new(output.chomp, process.exit_code)
    end

    private

    # on heroku, tty isn't avaiable. so we result to just running command through
    # bash. the downside to this, is that stuff colors aren't outputted because
    # processes don't think they're being in a terminal.
    def runner
      require 'pty'
      PTY.spawn('whoami')

      [ File.join(Buildbox.gem_root, "bin", "buildbox-pty") ]
    rescue
      [ "bash", "-c" ]
    end

    def expanded_directory
      File.expand_path(@directory)
    end
  end
end
