module Buildbox
  class Build
    attr_reader :uuid

    def initialize(options)
      @uuid       = options[:uuid]
      @repository = options[:repository]
      @commit     = options[:commit]
      @config     = options[:config]
      @failed     = false
      @results    = []
    end

    def start(observer = nil)
      @observer = observer

      unless build_path.exist?
        setup_build_path
        clone_repository
      end

      fetch_and_checkout
      build

      @results
    end

    private

    def setup_build_path
      run %{mkdir -p "#{build_path}"}
    end

    def clone_repository
      run %{git clone "#{@repository}" . -q}
    end

    def fetch_and_checkout
      run %{git clean -fd}
      run %{git fetch -q}
      run %{git checkout -qf "#{@commit}"}
    end

    def build
      @config[:build][:commands].each { |command| run command }
    end

    def folder_name
      @repository.gsub(/[^a-zA-Z0-9]/, '-')
    end

    def build_path
      Buildbox.root_path.join folder_name
    end

    def run(command)
      # don't run anoy more commands if the build has failed
      # at one of the steps
      return if @failed

      path    = build_path if build_path.exist?
      started = false

      result = Buildbox::Command.new(path).run(command) do |result, chunk|
        if started
          @observer.chunk(result)
          @results << result
        else
          @observer.started(result)
          started = true
        end
      end

      @observer.finished(result)

      # flag the build as failing, so we don't run any more commands.
      # this is a little hacky.
      @failed = true unless result.success?

      result
    end
  end
end
