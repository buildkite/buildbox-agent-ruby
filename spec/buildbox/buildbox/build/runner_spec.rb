require 'spec_helper'

describe Buildbox::Build::Runner do
  let(:build)    { Buildbox::Build.new(:uuid => '1234', :repository => 'repo', :commit => 'commit', :config => { :script => "rspec" }) }
  let(:observer) { Buildbox::Build::NullObserver.new }
  let(:runner)   { Buildbox::Build::Runner.new(build, observer) }

  describe "#run" do
    it "watches for magical points in the output and constructs result objects accordingly" do
      output1 = <<-OUTPUT
buildbox:begin:546a5ce1-c43b-4d12-b750-8b0fae8ec1afbuildbox:end:546a5ce1-c43b-4d12-b750-8b0fae8ec1af:0
buildbox:begin:2df513bc-68d2-49c8-85eb-acba41a9a2ca
cloned
      OUTPUT
      output2 = "great"
      output3 = <<-OUTPUT
awesomebuildbox:end:2df513bc-68d2-49c8-85eb-acba41a9a2ca:0
      OUTPUT
      output4 = <<-OUTPUT
buildbox:begin:799932c3-8199-4ede-94be-9138528ca25f
awesome output is awesopme
buildbox:end:799932c3-8199-4ede-94be-9138528ca25f:1
      OUTPUT

      Buildbox::Command.stub(:run).and_yield(output1).and_yield(output2).and_yield(output3).and_yield(output4)

      runner.run

      pending
    end
  end
end
