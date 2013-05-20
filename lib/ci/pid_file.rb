module CI
  class PidFile
    def exist?
      File.exist?(path)
    end

    def path
      CI.root_path.join("ci.pid")
    end

    def read
      File.readlines(path).first.to_i
    end

    def save
      File.open(path, 'w+') { |file| file.write(Process.pid.to_s) }
    end

    def delete
      File.delete(path)
    end
  end
end
