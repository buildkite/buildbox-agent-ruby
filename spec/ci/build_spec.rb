require 'spec_helper'

describe CI::Build do
  let(:build) { CI::Build.new(1, 2, "git@github.com:keithpitt/ci-ruby.git", "67b15b704e0", "rspec") }

  describe "#start" do
    let(:build_path) { double }
    let(:root_path)  { double(:join => build_path) }
    let(:command)    { double(:run => true, :run! => true) }

    before do
      CI.stub(:root_path => root_path)
      CI::Command.stub(:new => command)
    end

    context "with a new checkout" do
      before do
        build_path.stub(:exist? => false, :mkpath => true)
      end

      it "creates a directory for the build" do
        build_path.should_receive(:mkpath)

        build.start
      end

      it "clones the repo" do
        command.should_receive(:run!).with(%{git clone "git@github.com:keithpitt/ci-ruby.git" .}).once

        build.start
      end
    end

    context "with an existing checkout" do
      before do
        build_path.stub(:exist? => true)
      end

      it "doesn't checkout the repo again" do
        command.should_not_receive(:run!).with(%{git clone "git@github.com:keithpitt/ci-ruby.git" .})

        build.start
      end

      it "cleans, fetches and checks out the commit" do
        command.should_receive(:run!).with(%{git clean -fd}).ordered
        command.should_receive(:run!).with(%{git fetch}).ordered
        command.should_receive(:run!).with(%{git checkout -qf "67b15b704e0"}).ordered

        build.start
      end

      it "runs the command" do
        command.should_receive(:run).with(%{rspec})

        build.start
      end
    end
  end
end
