# encoding: UTF-8

require 'spec_helper'

describe Buildbox::Client::Configuration do
  subject(:configuration) { Buildbox::Client::Configuration.new }

  it "has a default endpoint" do
    configuration.endpoint.should =~ /buildbox/
  end
end
