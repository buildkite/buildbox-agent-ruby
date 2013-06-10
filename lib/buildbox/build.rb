module Buildbox
  class Build
    attr_reader :uuid

    def initialize(options)
      @uuid       = options[:uuid]
      @repository = options[:repository]
      @commit     = options[:commit]
      @command    = options[:command] || "bundle && rspec"
    end

    def start(&block)
      checkout
      update

      @result = command.run(@command) do |chunk|
        yield(chunk) if block_given?
      end
    end

    private

    def checkout
      unless build_path.exist?
        build_path.mkpath

        command.run! %{git clone "#{@repository}" .}
      end
    end

    def update
      command.run! %{git clean -fd}
      command.run! %{git fetch}
      command.run! %{git checkout -qf "#{@commit}"}
    end

    def build_path
      Buildbox.root_path.join folder_name
    end

    def folder_name
      @repository.gsub(/[^a-zA-Z0-9]/, '-')
    end

    def command
      Buildbox::Command.new(build_path)
    end
  end
end
