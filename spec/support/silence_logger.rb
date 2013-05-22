RSpec.configure do |config|
  config.before(:each) do
    logger = Logger.new(StringIO.new)

    Trigger.stub(:logger => logger)
  end
end
