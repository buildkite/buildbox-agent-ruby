module Trigger
  class Build
    attr_reader :uuid, :repository_uuid

    def initialize(options)
      @uuid            = options[:uuid]
      @repo            = options[:repo]
      @commit          = options[:commit]
      @repository_uuid = options[:repository_uuid]
      @command         = options[:command] || "bundle && rspec"
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

        command.run! %{git clone "#{@repo}" .}
      end
    end

    def update
      command.run! %{git clean -fd}
      command.run! %{git fetch}
      command.run! %{git checkout -qf "#{@commit}"}
    end

    def build_path
      Trigger.root_path.join folder_name
    end

    def folder_name
      @repo.gsub(/[^a-zA-Z0-9]/, '-')
    end

    def command
      Trigger::Command.new(build_path)
    end
  end
end
