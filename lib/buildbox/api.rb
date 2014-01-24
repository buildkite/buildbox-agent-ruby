require 'faraday'
require 'faraday_middleware'
require 'delegate'

module Buildbox
  class API
    class AgentNotFoundError < StandardError; end

    def initialize(config = Buildbox.config, logger = Buildbox.logger)
      @config = config
      @logger = logger
    end

    def agent(access_token, options)
      connection.request(:put, access_token, options)
    rescue Buildbox::Connection::NotFoundError => e
      raise AgentNotFoundError.new(e.message)
    end

    def next_build(access_token)
      response = connection.request(:get, "#{access_token}/builds/queue/next")

      if build = response['build']
        Buildbox::Build.new(build)
      else
        nil
      end
    end

    def update_build(access_token, build, options)
      connection.request(:put, "#{access_token}/builds/#{build.id}", options)
    end

    def create_artifacts(access_token, build, artifacts)
      connection.request(:post, "#{access_token}/builds/#{build.id}/artifacts", 'artifacts' => artifacts.map(&:as_json))
    end

    def update_artifact(access_token, build, artifact_id, options)
      connection.request(:put, "#{access_token}/builds/#{build.id}/artifacts/#{artifact_id}", options)
    end

    private

    def connection
      @connection ||= begin
                        ca_file = Buildbox.gem_path.join("lib", "certs", "cacert.pem").to_s

                        Buildbox::Connection.new(@logger, @config.api_endpoint, ca_file)
                      end
    end
  end
end
