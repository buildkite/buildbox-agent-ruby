require 'celluloid'

module Buildbox
  class Agent
    include Celluloid
    include Celluloid::Logger

    def initialize(access_token, api = Buildbox::API.new)
      @api           = api
      @access_token  = access_token
      @uploader_pool = Uploader.pool(size: 10) # upload 10 things at a time
    end

    def process
      return if @current_build

      if @current_build = next_build
        @api.update_build(@access_token, @current_build, :agent_accepted => @access_token)

        montior = Monitor.new(@current_build, @access_token, @api).async.monitor
        runner  = Runner.start(@current_build)

        @current_build.artifact_paths.each do |glob|
          files = Artifact.files_to_upload(runner.build_directory, glob)

          files.each_pair do |relative_path, absolute_path|
            credentials = @api.create_artifact(@access_token, @current_build, path: relative_path,
                                                                              file_size: File.size(absolute_path))

            @uploader_pool.upload(credentials, absolute_path)
          end
        end
      end

      @current_build = nil
    end

    private

    def next_build
      @api.agent(@access_token, :hostname => hostname, :version => Buildbox::VERSION)
      @api.next_build(@access_token)
    rescue Buildbox::API::AgentNotFoundError
      warn "Agent `#{@access_token}` does not exist"
      nil
    end

    def hostname
      `hostname`.chomp
    end
  end
end
