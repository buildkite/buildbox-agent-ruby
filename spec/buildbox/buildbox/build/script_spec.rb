require 'spec_helper'

describe Buildbox::Build::Script do
  let(:script) { Buildbox::Build::Script.new }

  describe "#to_s" do
    it "generates a script that is runnable with magical points" do
      script.queue "1", %{cd hello}
      script.queue "2", %{say "hello";}

      expected = <<-BUFFER
echo "buildbox:begin:1";
cd hello;
echo "buildbox:end:1";
echo "buildbox:begin:2";
say "hello";;
echo "buildbox:end:2";
      BUFFER

      script.to_s.should == expected.chomp
    end
  end
end
