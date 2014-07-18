if ENV['COVERAGE'] and RUBY_VERSION =~ /^1.9/
  require 'simplecov'
  require 'simplecov-rcov'

  SimpleCov.formatter = SimpleCov::Formatter::RcovFormatter
  SimpleCov.start
end

require 'om'
require 'rspec'
require 'equivalent-xml/rspec_matchers'
require 'samples'
require 'logger'

OM.logger = Logger.new(STDERR)

RSpec.configure do |config|
end

def fixture(file)
  File.new(File.join(File.dirname(__FILE__), 'fixtures', file))
end
