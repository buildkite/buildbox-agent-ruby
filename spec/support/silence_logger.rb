RSpec.configure do |config|
  config.before(:each) do
    logger = Logger.new(StringIO.new)

    CI.stub(:logger => logger)
  end
end
