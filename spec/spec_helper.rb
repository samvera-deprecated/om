require 'om'
require 'rspec'
require 'equivalent-xml/rspec_matchers'
require 'ruby-debug'

RSpec.configure do |config|
  config.mock_with :mocha
end

def fixture(file)
  File.new(File.join(File.dirname(__FILE__), 'fixtures', file))
end
