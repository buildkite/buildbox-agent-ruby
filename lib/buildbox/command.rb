require 'childprocess'

module Buildbox
  class Command
    class Result < Struct.new(:output, :exit_status)
    end

    def self.command(command, options = {}, &block)
      arguments = [ "bash", "-c", command ]

      new(arguments, options).start(&block)
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
      r, w = IO.pipe
      fd = IO.sysopen("/dev/tty", "w")
      a = IO.new(fd, "w")

      arguments         = [ *@arguments ].map(&:to_s) # all arguments must be a string
      process           = ChildProcess.build(*arguments)
      process.cwd       = expanded_directory
      process.io.stdout = process.io.stderr = w

      @environment.each_pair do |key, value|
        process.environment[key] = value
      end

      process.start
      w.close

      output = ""
      begin
        loop do
          chunk         = r.readpartial(10240)
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

    def expanded_directory
      File.expand_path(@directory)
    end
  end
end
