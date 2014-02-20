require 'optparse'

module Buildbox
  class CLI
    attr_reader :argv

    def initialize(argv)
      @argv     = argv
      @commands = {}
      @options  = {}

      @commands['agent:setup'] = OptionParser.new do |opts|
        opts.banner = "Usage: buildbox agent:setup [token]"

        opts.on("--help", "You're looking at it.") do
          puts @commands['agent:setup']
          exit
        end
      end

      @commands['agent:start'] = OptionParser.new do |opts|
        opts.banner = "Usage: buildbox agent:start"

        opts.on("--help", "You're looking at it.") do
          puts @commands['agent:start']
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

        if command == "agent:start"
          Buildbox::Server.new.start
        elsif command == "agent:setup"
          if @argv.length == 0
            puts "No token provided"
            exit 1
          end

          access_token = @argv.first
          new_access_tokens = Buildbox.config.agent_access_tokens + [access_token]
          Buildbox.config.update(:agent_access_tokens => new_access_tokens.uniq)

          puts "Successfully added agent access token"
          puts "You can now start the agent with: buildbox agent:start."
          puts "If the agent is already running, you'll have to restart it for the new changes to take effect"
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

  agent:setup [access_token] # set the access token for the agent
  agent:start                # start the buildbox agent
  version  #  display version

HELP
    end
  end
end
