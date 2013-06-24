require 'spec_helper'

describe Buildbox::Script do

  let(:script) { Buildbox::Script.new }

  describe "#split" do
    it "splits the passed in string into chunks of buildbox magical strings" do
      output = <<-OUTPUT
buildbox-begin:{"identifier":"1","command":"cd .","action":"begin"}:buildbox-end
buildbox-begin:{"identifier":"1","command":"cd .","action":"end","exit_status":"{0}"}:buildbox-end
buildbox-begin:{"identifier":"2","command":"echo \\"hello\\"","action":"begin"}:buildbox-end
hello
buildbox-begin:{"identifier":"2","command":"echo \\"hello\\"","action":"end","exit_status":"{0}"}:buildbox-end
      OUTPUT

      lines = Buildbox::Script.split(output)
      infos = []

      lines.each do |line|
        if Buildbox::Script.matches?(line)
          infos << Buildbox::Script.parse(line)
        end
      end

      infos.should == [
        {"identifier"=>"1", "command"=>"cd .", "action"=>"begin"},
        {"identifier"=>"1", "command"=>"cd .", "action"=>"end", "exit_status"=>"{0}"},
        {"identifier"=>"2", "command"=>"echo \"hello\"", "action"=>"begin"},
        {"identifier"=>"2", "command"=>"echo \"hello\"", "action"=>"end", "exit_status"=>"{0}"}
      ]
    end
  end

  describe "#parse" do
    it "turns a magical buildbox line into a json hash" do
      info = Buildbox::Script.parse(%{\nbuildbox-begin:{"identifier":"2","command":"say \\"hello\\"","action":"begin"}:buildbox-end})

      info.should == { "identifier" => "2", "command" => "say \"hello\"", "action" => "begin" }
    end
  end

  describe "#to_s" do
    it "generates a script that is runnable with magical points" do
      script.queue "1", %{cd hello}
      script.queue "2", %{say "hello"}

      script.to_s.should == "#!/bin/bash\nset -e\necho \"buildbox-begin:{\\\"identifier\\\":\\\"1\\\",\\\"command\\\":\\\"cd hello\\\",\\\"action\\\":\\\"begin\\\"}:buildbox-end\";\ncd hello\necho \"buildbox-begin:{\\\"identifier\\\":\\\"1\\\",\\\"command\\\":\\\"cd hello\\\",\\\"action\\\":\\\"end\\\",\\\"exit_status\\\":\\\"$?\\\"}:buildbox-end\";\necho \"buildbox-begin:{\\\"identifier\\\":\\\"2\\\",\\\"command\\\":\\\"say \\\\\\\"hello\\\\\\\"\\\",\\\"action\\\":\\\"begin\\\"}:buildbox-end\";\nsay \"hello\"\necho \"buildbox-begin:{\\\"identifier\\\":\\\"2\\\",\\\"command\\\":\\\"say \\\\\\\"hello\\\\\\\"\\\",\\\"action\\\":\\\"end\\\",\\\"exit_status\\\":\\\"$?\\\"}:buildbox-end\";"
    end
  end
end
