require 'fileutils'
require 'tempfile'

module Buildbox
  class Artifact::Collector
    include Celluloid::Logger

    MAX_ARTIFACT_LIMIT = 500

    class TooManyArtifactsError < RuntimeError; end

    def self.collect_and_copy(build_directory, glob)
      new(build_directory, glob).collect_and_copy
    end

    def initialize(build_directory, glob)
      @build_directory = build_directory
      @glob            = glob
    end

    def collect_and_copy
      index     = 0
      artifacts = []
      tmpdir    = Dir.mktmpdir

      globbed_files.each do |file|
        raise TooManyArtifactsError if index > MAX_ARTIFACT_LIMIT

        absolute_path = File.expand_path(file, @build_directory)
        copy_to_path  = File.join(tmpdir, file)

        if File.file?(absolute_path)
          artifacts << Artifact.create(@glob, file, copy_to_path, absolute_path)

          FileUtils.mkdir_p(File.dirname(copy_to_path))
          FileUtils.cp(absolute_path, copy_to_path)
        end

        index += 1
      end

      artifacts
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
