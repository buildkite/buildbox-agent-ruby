module CI
  class Build
    def initialize(project_id, build_id, repo, commit, command)
      @project_id = project_id
      @build_id   = build_id
      @repo       = repo
      @commit     = commit
      @command    = command
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
      CI.root_path.join folder_name
    end

    def folder_name
      name = @repo.match(/:(.+).git/)[1]

      "#{@project_id}-#{name.gsub(/\//, '-')}"
    end

    def command
      CI::Command.new(build_path)
    end
  end
end
