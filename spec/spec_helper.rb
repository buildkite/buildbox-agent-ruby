require 'rubygems'
require 'bundler/setup'

require 'buildbox'

SPEC_PATH     = Pathname.new(File.expand_path('..', __FILE__))
FIXTURES_PATH = SPEC_PATH.join('fixtures')
TEMP_PATH     = SPEC_PATH.join('tmp')

Dir[SPEC_PATH.join("support/**/*.rb")].each { |f| require f }

RSpec.configure do |config|
  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = "random"
end
