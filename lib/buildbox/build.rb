module Buildbox
  class Build
    attr_reader :uuid

    def initialize(options)
      @uuid       = options[:uuid]
      @repository = options[:repository]
      @commit     = options[:commit]
      @config     = options[:config]
    end

    def start(&block)
      @block   = block
      @results = []

      unless build_path.exist?
        setup_build_path && clone_repository
      end

      fetch_and_checkout && build

      @results.flatten
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
      @config[:build][:commands].each { |command| run command }
    end

    def folder_name
      @repository.gsub(/[^a-zA-Z0-9]/, '-')
    end

    def build_path
      Buildbox.root_path.join folder_name
    end

    def run(command)
      path = build_path if build_path.exist?

      @results << result = Buildbox::Command.new(path).run(command) do |result, chunk|
        @block.call(result)
      end

      @block.call(result)

      result
    end
  end
end
