require 'spec_helper'

describe Buildbox::Build do
  let(:build) { Buildbox::Build.new(:uuid => '1234', :repository => "git@github.com:keithpitt/ci-ruby.git", :commit => "67b15b704e0", :command => "rspec", :config => { :build => { :commands => [ "rspec" ] }}) }

  describe "#start" do
    let(:build_path) { double }
    let(:root_path)  { double(:join => build_path) }
    let(:result)     { double(:success? => true) }
    let(:command)    { double(:run => result, :run! => result) }
    let(:observer)   { double.as_null_object }

    before do
      Buildbox.stub(:root_path => root_path)
      Buildbox::Command.stub(:new => command)
    end

    context "with a new checkout" do
      before do
        build_path.stub(:exist? => false)
      end

      it "creates a folder for the build" do
        root_path.should_receive(:join).with('git-github-com-keithpitt-ci-ruby-git')

        build.start(observer)
      end

      it "clones the repo" do
        command.should_receive(:run).with(%{git clone "git@github.com:keithpitt/ci-ruby.git" . -q}).once

        build.start(observer)
      end
    end

    context "with an existing checkout" do
      before do
        build_path.stub(:exist? => true)
      end

      it "doesn't checkout the repo again" do
        command.should_not_receive(:run).with(%{git clone "git@github.com:keithpitt/ci-ruby.git" . -q})

        build.start(observer)
      end

      it "cleans, fetches and checks out the commit" do
        command.should_receive(:run).with(%{git clean -fd}).ordered
        command.should_receive(:run).with(%{git fetch -q}).ordered
        command.should_receive(:run).with(%{git checkout -qf "67b15b704e0"}).ordered

        build.start(observer)
      end

      it "runs the command" do
        command.should_receive(:run).with(%{rspec})

        build.start(observer)
      end
    end
  end
end
