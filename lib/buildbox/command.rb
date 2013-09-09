require 'childprocess'
require 'pty'

# Inspiration from:
# https://github.com/mitchellh/vagrant/blob/master/lib/vagrant/util/subprocess.rb

module Buildbox
  class Command
    # The chunk size for reading from subprocess IO.
    READ_CHUNK_SIZE = 4096

    attr_reader :output, :exit_status

    def self.run(command, options = {}, &block)
      runner = new(command, options)
      runner.start(&block)
      runner
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

      @output      = output.chomp
      @exit_status = process.exit_code
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
