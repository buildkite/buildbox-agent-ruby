module Buildbox
  class Script
    def initialize(build)
      @build = build
    end

    def name
      "#{@build.project.team.name}-#{@build.project.name}-#{@build.number}"
    end

    def path
      Buildbox.root_path.join(name)
    end

    def save
      File.open(path, 'w+') { |file| file.write(normalized_script) }
    end

    def delete
      File.delete(path)
    end

    private

    def normalized_script
      # normalize the line endings
      @build.script.gsub(/\r\n?/, "\n")
    end
  end
end
