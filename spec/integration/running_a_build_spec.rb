# encoding: UTF-8

require 'spec_helper'

describe 'running a build' do
  let(:commit) { "24b04991020e82630ef2ee1d880a6af3cbd4c895" }
  let(:env)    { { 'BUILDBOX_REPO' => FIXTURES_PATH.join("repo.git").to_s, 'BUILDBOX_COMMIT' => commit } }
  let(:build)  { Buildbox::Build.new(:project => { :id => "test", :team => { :id => "test" } }, :id => 'buildid', :env => env) }
  let(:runner) { Buildbox::Runner.new(build) }

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
      build.should be_finished
      build.parts.last.output.should =~ /1 example, 0 failures/
    end
  end

  context 'running a working build with a semi colon in the command' do
    let(:command) { "rspec test_spec.rb;" }

    it "returns a successfull result" do
      runner.start

      build.should be_success
      build.parts.last.output.should =~ /1 example, 0 failures/
    end
  end

  context 'running a failing build' do
    let(:commit) { "5e10fade9d87996aff68ab953e1b0990546f53a6" }

    it "returns a unsuccessfull result" do
      runner.start

      build.should_not be_success
      build.parts.last.output.should =~ /1 example, 1 failure/
    end
  end

  context 'running a failing build that has commands after the one that failed' do
    let(:commit)  { '2ac2f6560213aa67b0beb5f93752ba9bc5c17408' }

    it "returns a unsuccessfull result" do
      runner.start

      build.should_not be_success
      build.parts.last.output.should =~ /1 example, 1 failure/
    end
  end

  context 'accessing ENV variables with a ruby script' do
    let(:commit) { "814d7440ff99aa974a16f62bf74a5e332848d38e" }

    it "runs and returns the correct output" do
      env['FOO'] = "great"
      runner.start

      build.parts[4].output.should == env['BUILDBOX_REPO']
      build.parts.last.output.should == 'great'
    end
  end

  context 'running a failing build that returns a non standard exit status' do
    let(:commit) { "f20051c2ebf04cbf6fe28f8620b7a3c3da2f2fd4" }

    it "returns a unsuccessfull result" do
      runner.start

      build.should_not be_success
      build.parts.last.exit_status.should == 123
    end
  end

  context 'running a build with a .buildbox file inside' do
    let(:commit) { "96b3b1ccedd7e3d0c3d980a3f5efbd456e910f81" }

    it "returns a unsuccessfull result" do
      runner.start

      build.parts.last.output.should == 'Hello there!!'
    end
  end

  context 'a build that has a command with a syntax error' do
    let(:commit) { "8eef70ef24a36aa57fbacc0d759e312f51332c3d" }

    it "returns a unsuccessfull result" do
      runner.start

      build.should_not be_success

      # bash 3.2.48 prints "syntax error" in lowercase.
      # freebsd 9.1 /bin/sh prints "Syntax error" with capital S.
      # zsh 5.0.2 prints "parse error" which we do not handle.
      # localized systems will print the message in not English which
      # we do not handle either.
      build.parts.last.output.should =~ /(syntax|parse) error/i
    end
  end

  context 'running a build with a broken command' do
    let(:commit) { '99cc50613b66753e8baff6678287b77484f65398' }

    it "returns a unsuccessfull result" do
      runner.start

      build.should_not be_success
      # ubuntu: sh: 1: foobar: not found
      # osx: sh: foobar: command not found
      build.parts.last.output.should =~ /foobar.+not found/
    end
  end

  context 'running multiple builds in a row' do
    it "returns a successfull result when the build passes" do
      runner.start
      build.should be_success
      build.parts.last.output.should =~ /1 example, 0 failures/

      runner.start
      build.should be_success
      build.parts.last.output.should =~ /1 example, 0 failures/
    end
  end

  context 'running a working build from a thread' do
    it "returns a successfull result" do
      result = nil
      thread = Thread.new do
        result = runner.start
      end
      thread.join

      build.should be_success
      build.parts.last.output.should =~ /1 example, 0 failures/
    end
  end

  context 'running a failing build from a thread' do
    let(:commit) { "5e10fade9d87996aff68ab953e1b0990546f53a6" }

    it "returns a successfull result" do
      result = nil
      thread = Thread.new do
        result = runner.start
      end
      thread.join

      build.should_not be_success
      build.parts.last.output.should =~ /1 example, 1 failure/
    end
  end
end
