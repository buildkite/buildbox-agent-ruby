# encoding: UTF-8

require 'spec_helper'

describe Buildbox::Build do
  let(:build) { Buildbox::Build.new(:uuid => '1234', :repository => "git@github.com:keithpitt/ci-ruby.git", :commit => "67b15b704e0", :command => "rspec", :config => { :script => [ "rspec" ] }) }
end
