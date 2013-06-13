module Buildbox
  class Build
    attr_reader :uuid

    def initialize(options)
      @uuid       = options[:uuid]
      @repository = options[:repository]
      @commit     = options[:commit]
      @config     = options[:config]
    end

    def start(options)
      raise options.inspect

      @block   = block
      @results = []
      @index   = 0

      unless build_path.exist?
        @results << setup_build_path
        @results << clone_repository
      end

      @results << fetch_and_checkout
      @results << build

      options[:partial_result].call @results.flatten
    end

    private

    def setup_build_path
      run %{mkdir -p "#{build_path}"}
    end

    def clone_repository
      run %{git clone "#{@repository}" .}
    end

    def fetch_and_checkout
      run %{git clean -fd}
      run %{git fetch}
      run %{git checkout -qf "#{@commit}"}
    end

    def build
      @config[:build][:commands].each do |command|
        run command
      end
    end

    def folder_name
      @repository.gsub(/[^a-zA-Z0-9]/, '-')
    end

    def build_path
      Buildbox.root_path.join folder_name
    end

    def run(command)
      path   = build_path if build_path.exist?

      result = Buildbox::Command.new(path).run(command) do |chunk|
        @block.call(index, command, chunk)
        options[:partial_result].call "hi"
      end

      options[:finished_result].call result

      result
    end
  end
end
