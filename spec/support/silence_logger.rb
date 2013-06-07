RSpec.configure do |config|
  config.before(:each) do
    logger = Logger.new(StringIO.new)

    Buildbox.stub(:logger => logger)
  end
end
