# encoding: UTF-8

require 'spec_helper'

describe 'running a build' do
  let(:commit)    { "3e0c65433b241ff2c59220f80bcdcd2ebb7e4b96" }
  let(:command)   { "rspec test_spec.rb" }
  let(:build)     { Buildbox::Build.new(:project => { :name => "test", :team => { :name => "test" } }, :number => 1, :script => script) }
  let(:runner)    { Buildbox::Builder.new(build) }
  let(:script) do
<<-SCRIPT
echo `pwd`
if [ ! -d ".git" ]; then
  git clone "#{FIXTURES_PATH.join("repo.git").to_s}" ./
fi
git clean -fd
git checkout #{commit}
#{command}
SCRIPT
  end

  before do
    Buildbox.stub(:root_path).and_return(TEMP_PATH)
  end

  after do
    TEMP_PATH.rmtree if TEMP_PATH.exist?
  end

  context 'running a working build' do
    it "returns a successfull result" do
      runner.start

      build.should be_success
      build.output.should =~ /1 example, 0 failures/
    end
  end

  context 'running a working build with a semi colon in the command' do
    let(:command) { "rspec test_spec.rb;" }

    it "returns a successfull result" do
      runner.start

      build.should be_success
      build.output.should =~ /1 example, 0 failures/
    end
  end

=begin
  context 'running a failing build' do
    let(:commit) { "2d762cdfd781dc4077c9f27a18969efbd186363c" }

    it "returns a unsuccessfull result" do
      runner.start.last

      result.should_not be_success
      result.output.should =~ /1 example, 1 failure/
    end
  end

  context 'running a failing build that has commands after the one that failed' do
    let(:commit) { "2d762cdfd781dc4077c9f27a18969efbd186363c" }
    let(:command) { [ "rspec test_spec.rb;", "echo 'oh no you didnt!'" ] }

    it "returns a unsuccessfull result" do
      runner.start.last

      result.should_not be_success
      result.output.should =~ /1 example, 1 failure/
    end
  end

  context 'running a failing build that returns a non standard exit status' do
    let(:command) { [ "exit 123" ] }

    it "returns a unsuccessfull result" do
      runner.start.last

      result.should_not be_success
      result.exit_status.should == 123
    end
  end

  context 'a build that has a command with a syntax error' do
    let(:command) { [ 'if (', 'echo yay' ] }

    it "returns a unsuccessfull result" do
      runner.start.last

      result.should_not be_success

      # bash 3.2.48 prints "syntax error" in lowercase.
      # freebsd 9.1 /bin/sh prints "Syntax error" with capital S.
      # zsh 5.0.2 prints "parse error" which we do not handle.
      # localized systems will print the message in not English which
      # we do not handle either.
      result.output.should =~ /(syntax|parse) error/i
    end
  end

  context 'running a build with a broken command' do
    let(:command) { 'foobar' }

    it "returns a unsuccessfull result" do
      runner.start.last

      result.should_not be_success
      # ubuntu: sh: 1: foobar: not found
      # osx: sh: foobar: command not found
      result.output.should =~ /foobar.+not found/
    end
  end

  context 'running multiple builds in a row' do
    it "returns a successfull result when the build passes" do
      first_result  = runner.start.last
      second_result = runner.start.last

      first_result.should be_success
      first_result.output.should =~ /1 example, 0 failures/

      second_result.should be_success
      second_result.output.should =~ /1 example, 0 failures/
    end
  end

  context 'running a working build from a thread' do
    it "returns a successfull result" do
      result = nil
      thread = Thread.new do
        result = runner.start.last
      end
      thread.join

      result.should be_success
      result.output.should =~ /1 example, 0 failures/
    end
  end

  context 'running a failing build from a thread' do
    let(:commit) { "2d762cdfd781dc4077c9f27a18969efbd186363c" }

    it "returns a successfull result" do
      result = nil
      thread = Thread.new do
        result = runner.start.last
      end
      thread.join

      result.should_not be_success
      result.output.should =~ /1 example, 1 failure/
    end
  end
=end
end
