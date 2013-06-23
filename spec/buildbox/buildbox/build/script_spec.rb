require 'spec_helper'

describe Buildbox::Build::Script do
  let(:build)    { Buildbox::Build.new(:uuid => '1234', :repository => 'repo', :commit => 'commit', :config => { :script => "rspec" }) }
  let(:script)   { Buildbox::Build::Script.new(build) }

  before do
    build.stub(:path => Pathname.new('/tmp/foo'))
  end

  describe "#to_s" do
    it "generates the correct script to run" do
      script.to_s.should include('rspec;')
    end
  end
end
