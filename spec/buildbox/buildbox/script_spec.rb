require 'spec_helper'

describe Buildbox::Script do

  let(:script) { Buildbox::Script.new }

  describe "#split" do
    it "splits the passed in string into chunks of buildbox magical strings" do
      output = <<-OUTPUT
buildbox-begin:{"identifier":"1","command":"cd ."}:buildbox-end
buildbox-begin:{"identifier":"2","command":"echo \\"hello\\""}:buildbox-end
hello
      OUTPUT

      lines = Buildbox::Script.split(output)
      infos = []

      lines.each do |line|
        if Buildbox::Script.matches?(line)
          infos << Buildbox::Script.parse(line)
        end
      end

      infos.should == [
        {"identifier"=>"1", "command"=>"cd ."},
        {"identifier"=>"2", "command"=>"echo \"hello\""},
      ]
    end
  end

  describe "#parse" do
    it "turns a magical buildbox line into a json hash" do
      info = Buildbox::Script.parse(%{\nbuildbox-begin:{"identifier":"2","command":"say \\"hello\\""}:buildbox-end})

      info.should == { "identifier" => "2", "command" => "say \"hello\"" }
    end
  end

  describe "#to_s" do
    it "generates a script that is runnable with magical points" do
      script.queue "1", %{cd hello}
      script.queue "2", %{say "hello"}

      script.to_s.should == "#!/bin/bash\nset -e\necho \"buildbox-begin:{\\\"identifier\\\":\\\"1\\\",\\\"command\\\":\\\"cd hello\\\"}:buildbox-end\";\ncd hello\necho \"buildbox-begin:{\\\"identifier\\\":\\\"2\\\",\\\"command\\\":\\\"say \\\\\\\"hello\\\\\\\"\\\"}:buildbox-end\";\nsay \"hello\""
    end
  end
end
