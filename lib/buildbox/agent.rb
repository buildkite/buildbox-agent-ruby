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

        @current_build.artifact_paths.each do |path|
          upload_artifacts_from(runner.build_directory, path)
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

    def upload_artifacts_from(build_directory, artifact_path)
      files = Artifact.files_to_upload(build_directory, artifact_path)

      files.each_pair do |relative_path, absolute_path|
        artifact = @api.create_artifact(@access_token, @current_build,
                                        path: relative_path,
                                        file_size: File.size(absolute_path))

        @uploader_pool.upload(artifact[:uploader], absolute_path) do |state, response|
          @api.update_artifact(@access_token, @current_build, artifact[:id], state: state)
        end
      end
    rescue => e
      error "There was an error uploading artifacts for path: #{artifact_path} (#{e.class.name}: #{e.message})"
      e.backtrace[0..3].each { |line| error(line) }
    end
  end
end
