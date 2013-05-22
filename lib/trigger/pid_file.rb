module Trigger
  class PidFile
    def exist?
      File.exist?(path)
    end

    def path
      Trigger.root_path.join("ci.pid")
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
