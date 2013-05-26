require 'spec_helper'

describe Trigger::Configuration do
  subject(:configuration) { Trigger::Configuration.new }

  it "has a default endpoint" do
    configuration.endpoint.should =~ /triggerci/
  end
end
