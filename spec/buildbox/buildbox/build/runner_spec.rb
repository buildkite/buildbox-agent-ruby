require 'spec_helper'

describe Buildbox::Build::Runner do
  let(:build)    { Buildbox::Build.new(:uuid => '1234', :repository => 'repo', :commit => 'commit', :config => { :script => "rspec" }) }
  let(:observer) { Buildbox::Build::NullObserver.new }
  let(:runner)   { Buildbox::Build::Runner.new(build, observer) }

  describe "#run" do
    it "watches for magical points in the output and constructs result objects accordingly" do
      output1 = <<-OUTPUT
buildbox-begin:{"identifier":"1","command":"cd hello","action":"begin"}:buildbox-end
      OUTPUT
      output2 = "lol.sh: line 2: cd: hello: No such file or directory"
      output3 = <<-OUTPUT
buildbox-begin:{"identifier":"1","command":"cd hello","action":"end","exit_status":"0"}:buildbox-endbuildbox-begin:{"identifier":"2","command":"say \\"hello\\";","action":"begin"}:buildbox-end
      OUTPUT
      output4 = <<-OUTPUT
hellobuildbox-begin:{"identifier":"2","command":"say \\"hello\\";","action":"end","exit_status":"1"}:buildbox-end
      OUTPUT

      Buildbox::Command.stub(:run).and_yield(output1).and_yield(output2).and_yield(output3).and_yield(output4)
      parts = runner.run

      parts[0].uuid.should == "1"
      parts[0].command.should == "cd hello"
      parts[0].output.should == "lol.sh: line 2: cd: hello: No such file or directory"
      parts[0].exit_status.should == 0

      parts[1].uuid.should == "2"
      parts[1].command.should == "say \"hello\";"
      parts[1].output.should == "hello"
      parts[1].exit_status.should == 1
    end
  end
end
