require 'spec_helper'

describe 'running a build' do
  let(:root_path) { Pathname.new(TEMP_PATH) }
  let(:commit)    { "3e0c65433b241ff2c59220f80bcdcd2ebb7e4b96" }
  let(:command)   { "rspec test_spec.rb" }
  let(:build)     { CI::Build.new(:project_id => 1, :build_id => 1, :repo => File.join(SUPPORT_PATH, "repo.git"), :commit => commit, :command => command) }

  before do
    CI.stub(:root_path).and_return(root_path)
  end

  after do
    root_path.rmtree if root_path.exist?
  end

  context 'running a working build' do
    it "returns a successfull result" do
      result = build.start

      result.should be_success
      result.output.should =~ /1 example, 0 failures/
    end
  end

  context 'running a failing build' do
    let(:commit) { "2d762cdfd781dc4077c9f27a18969efbd186363c" }

    it "returns a unsuccessfull result" do
      result = build.start

      result.should_not be_success
      result.output.should =~ /1 example, 1 failure/
    end
  end

  context 'running a build with a broken command' do
    let(:command) { 'foobar' }

    it "returns a unsuccessfull result" do
      result = build.start

      result.should_not be_success
      result.output.should == "sh: foobar: command not found"
    end
  end
end
