require 'spec_helper'

describe Trigger do
  describe ".configure" do
    it "allows you to pass a block to configure Trigger" do
      Trigger.configure do |config|
        config.endpoint = 'triggerci.dev'
      end

      Trigger.configuration.endpoint.should == 'triggerci.dev'
    end
  end
end
