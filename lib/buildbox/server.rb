require 'celluloid'

module Buildbox
  class Server
    INTERVAL = 5

    def initialize(config = Buildbox.config, logger = Buildbox.logger)
      @config = config
      @logger = logger
      @supervisors = []
    end

    def start
      Celluloid.logger = @logger
      Celluloid::Actor[:artifact_poster_pool] = Artifact::Poster.pool

      agent_access_tokens.each do |access_token|
        @supervisors << Buildbox::Agent.supervise(access_token)

        @logger.info "Agent with access token `#{access_token}` has started."
      end

      loop do
        @supervisors.each do |supervisor|
          supervisor.actors.first.async.process
        end

        GC.start

        # Generate a new set of objects
        if ENV['PROFILE']
          objects = Hash.new(0)

          ObjectSpace.each_object do |o|
            objects[o.class] += 1
          end

          if !@previous_objects.nil?
            diff = {}

            objects.each_pair do |key, new_value|
              old_value = @previous_objects[key]

              if old_value > new_value
                diff[key] = "+#{old_value - new_value} (#{new_value})"
              elsif new_value < old_value
                diff[key] = "-#{new_value - old_value} (#{new_value})"
              else
                # diff[key] = old_value
              end
            end

            puts "=== OBJECT COUNT CHANGES ==="
            diff.each_pair do |key, value|
              puts "#{key}: #{value}"
            end
            puts "============================"
          else
            sorted_objects = objects.sort_by { |key, value| value }.reverse
            sorted_objects.each do |pair|
              puts "#{pair[0]}: #{pair[1]}"
            end
          end

          @previous_objects = objects.dup
        end

        wait INTERVAL
      end
    end

    private

    def wait(interval)
      @logger.debug "Sleeping for #{interval} seconds"

      sleep interval
    end

    def agent_access_tokens
      @config.agent_access_tokens
    end
  end
end
