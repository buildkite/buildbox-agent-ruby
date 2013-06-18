# encoding: UTF-8

require 'spec_helper'

describe Buildbox::Configuration do
  subject(:configuration) { Buildbox::Configuration.new }

  it "has a default endpoint" do
    configuration.endpoint.should =~ /buildbox/
  end
end
