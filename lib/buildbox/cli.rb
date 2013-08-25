require 'optparse'

module Buildbox
  class CLI
    attr_reader :argv

    def initialize(argv)
      @argv     = argv
      @commands = {}
      @options  = {}

      @commands['worker:start'] = OptionParser.new do |opts|
        opts.banner = "Usage: buildbox worker:start"

        opts.on("--help", "You're looking at it.") do
          puts @commands['worker:start']
          exit
        end
      end

      @commands['worker:setup'] = OptionParser.new do |opts|
        opts.banner = "Usage: buildbox worker:setup [token]"

        opts.on("--help", "You're looking at it.") do
          puts @commands['worker:setup']
          exit
        end
      end

      @commands['version'] = OptionParser.new do |opts|
        opts.banner = "Usage: buildbox version"
      end
    end

    def parse
      global.order!

      command = @argv.shift

      if command
        if @commands.has_key?(command)
          @commands[command].parse!
        else
          puts "`#{command}` is an unknown command"
          exit 1
        end

        if command == "version"
          puts Buildbox::VERSION
          exit
        end

        if command == "worker:start"
          Buildbox::Worker.new(Buildbox.config.worker_access_tokens).start
        elsif command == "worker:setup"
          if @argv.length == 0
            puts "No token provided"
            exit 1
          end

          access_token = @argv.first
          worker_access_tokens = Buildbox.config.worker_access_tokens
          Buildbox.config.update(:worker_access_tokens => worker_access_tokens << access_token)

          puts "Successfully added worker access token"
          puts "You can now start the worker with `buildbox worker:start`"
        end
      else
        puts global.help
      end
    end

    private

    def global
      @global ||= OptionParser.new do |opts|
        opts.version = Buildbox::VERSION
        opts.banner  = 'Usage: buildbox COMMAND [command-specific-actions]'

        opts.separator help
      end
    end

    def help
<<HELP

  worker   #  worker management (setup, server)
  version  #  display version

HELP
    end
  end
end
