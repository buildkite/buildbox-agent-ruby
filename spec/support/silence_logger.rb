# encoding: UTF-8

require 'logger'
require 'celluloid'

RSpec.configure do |config|
  config.before(:each) do
    logger = Logger.new(StringIO.new)

    Celluloid.logger = logger
  end
end
