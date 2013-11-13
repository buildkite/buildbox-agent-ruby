require 'spec_helper'

describe Buildbox::Artifact::Collector do
  let(:directory) { File.join(FIXTURES_PATH, "artifact-globber") }

  def test_for_files(files, expected)
    expected.each do |path|
      expect(files.map(&:name)).to include(path)
      expect(File.exist?(files.find{ |f| f.name == path }.path)).to be_true
    end
  end

  describe "#collect_and_copy" do
    it "handles specific files" do
      files = Buildbox::Artifact::Collector.collect_and_copy(directory, "foo.txt")

      expect(files.length).to eql(1)
      test_for_files(files, %w(foo.txt))
    end

    it "handles globs" do
      files = Buildbox::Artifact::Collector.collect_and_copy(directory, "bar/**/*.txt")

      expect(files.length).to eql(4)
      test_for_files(files, %w(bar/bang.txt bar/bang1.txt bar/bang2.txt bar/inside-bar/bang3.txt))
    end

    it "handles absolute globs" do
      files = Buildbox::Artifact::Collector.collect_and_copy(directory, File.join(File.expand_path(directory), "**/*.txt"))
      expected_files = %w(foo.txt bar/bang.txt bar/bang1.txt bar/bang2.txt bar/inside-bar/bang3.txt).map do |file|
        File.join(directory, file)
      end

      expect(files.length).to eql(5)
      test_for_files(files, expected_files)
    end

    it "handles specifying everything under a folder" do
      files = Buildbox::Artifact::Collector.collect_and_copy(directory, "coverage/**/*")

      expect(files.length).to eql(25)
      test_for_files(files, %w(coverage/index.html coverage/assets/0.8.0/application.js))
    end
  end
end
