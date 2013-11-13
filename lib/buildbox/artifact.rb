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
      tmpdir       = Dir.mktmpdir
      file_hash    = {}

      globbed_files.each do |file|
        absolute_path = File.expand_path(file, @build_directory)
        copy_to_path  = File.join(tmpdir, file)

        if File.file?(absolute_path)
          file_hash[file] = copy_to_path

          FileUtils.mkdir_p(File.dirname(copy_to_path))
          FileUtils.cp(absolute_path, copy_to_path)
        end
      end

      file_hash
    end

    private

    def glob_path
      Pathname.new(@glob)
    end

    def build_directory_path
      Pathname.new(@build_directory)
    end

    def globbed_files
      if glob_path.relative?
        Dir.chdir(build_directory_path.expand_path) { Dir.glob(glob_path) }
      else
        Dir.glob(glob_path)
      end
    end
  end
end
