if ENV['COVERAGE'] && RUBY_VERSION =~ /^1.9/
  require 'simplecov'
  require 'simplecov-rcov'
  SimpleCov.formatter = SimpleCov::Formatter::RcovFormatter
  SimpleCov.start
end

require 'om'
require 'rspec'
require 'equivalent-xml/rspec_matchers'

RSpec.configure do |config|

end

def fixture(file)
  File.new(File.join(File.dirname(__FILE__), 'fixtures', file))
end
