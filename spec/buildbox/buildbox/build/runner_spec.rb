require 'spec_helper'

describe Buildbox::Build::Runner do
  let(:build)    { Buildbox::Build.new(:uuid => '1234', :repository => 'repo', :commit => 'commit', :config => { :script => "rspec" }) }
  let(:observer) { Buildbox::Build::NullObserver.new }
  let(:script)   { double(:to_s => 'yolo') }
  let(:runner)   { Buildbox::Build::Runner.new(build, observer) }

  before do
    build.stub(:path => Pathname.new('/tmp/foo'))
  end

  describe "#run" do
    it "generates the correct script to run" do
      SecureRandom.stub(:uuid => 'uuid')
      Buildbox::Command.stub(:run)
      Buildbox::Build::Script.stub(:new => script)

      script.should_receive(:queue).with('uuid', %{mkdir -p "/tmp/foo"}).ordered
      script.should_receive(:queue).with('uuid', %{git clone "repo" "/tmp/foo" -q}).ordered
      script.should_receive(:queue).with('uuid', %{cd "/tmp/foo"}).ordered
      script.should_receive(:queue).with('uuid', %{git clean -fd}).ordered
      script.should_receive(:queue).with('uuid', %{git fetch -q}).ordered
      script.should_receive(:queue).with('uuid', %{git checkout -qf "commit"}).ordered
      script.should_receive(:queue).with('uuid', %{rspec}).ordered

      runner.run
    end

    it "watches for magical points in the output and constructs result objects accordingly" do
      output1 = <<-OUTPUT
buildbox:begin:546a5ce1-c43b-4d12-b750-8b0fae8ec1afbuildbox:end:0:546a5ce1-c43b-4d12-b750-8b0fae8ec1af
buildbox:begin:2df513bc-68d2-49c8-85eb-acba41a9a2ca
cloned
      OUTPUT
      output2 = "great"
      output3 = <<-OUTPUT
awesomebuildbox:end:0:2df513bc-68d2-49c8-85eb-acba41a9a2ca
      OUTPUT
      output4 = <<-OUTPUT
buildbox:begin:799932c3-8199-4ede-94be-9138528ca25f
awesome output is awesopme
buildbox:end:1:799932c3-8199-4ede-94be-9138528ca25f
      OUTPUT

      Buildbox::Command.stub(:run).and_yield(output1).and_yield(output2).and_yield(output3).and_yield(output4)

      runner.run
    end
  end
end
