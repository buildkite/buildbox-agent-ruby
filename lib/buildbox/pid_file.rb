module Buildbox
  class PidFile
    def exist?
      File.exist?(path)
    end

    def path
      Buildbox.root_path.join("buildbox.pid")
    end

    def pid
      File.readlines(path).first.to_i
    end

    def save
      File.open(path, 'w+') { |file| file.write(Process.pid.to_s) }
    end

    def delete
      value = pid
      File.delete(path)
      value
    end
  end
end
