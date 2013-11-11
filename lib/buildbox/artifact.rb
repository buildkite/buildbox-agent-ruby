require 'fileutils'
require 'tempfile'

module Buildbox
  class Artifact
    include Celluloid::Logger

    def self.files_to_upload(build_directory, glob)
      new(build_directory, glob).files_to_upload
    end

    def initialize(build_directory, glob)
      @build_directory = build_directory
      @glob            = glob
    end

    def files_to_upload
      tmpdir           = Dir.mktmpdir
      path_to_absolute = {}

      copy_files_to_upload(tmpdir).each do |file|
        path_to_absolute[relativize_to_dir(file, tmpdir)] = file
      end

      path_to_absolute
    end

    private

    def copy_files_to_upload(dir)
      expanded_directory = File.expand_path(@build_directory)
      absolute_glob      = File.expand_path(@glob, expanded_directory)

      target_files = Dir.glob(absolute_glob)

      target_files.each do |file|
        relative_path = relativize_to_dir(file, expanded_directory)
        copy_to       = File.join(dir, relative_path)

        if File.file?(file)
          FileUtils.mkdir_p(File.dirname(copy_to))
          FileUtils.cp(file, copy_to)
        end
      end

      # Grab all the files we're going to upload.
      Dir.glob(File.join(dir, "**", "*")).reject { |file| File.directory?(file) }
    end

    # /foo/build-directory/something.txt => /something.txt
    # /var/random/something.txt => /var/random/something.txt
    def relativize_to_dir(path, directory)
      if path.to_s.index(directory.to_s) == 0
        parts = path.to_s.split(directory.to_s)
        parts.shift
        parts.join(directory.to_s)
      else
        path
      end
    end
  end
end
