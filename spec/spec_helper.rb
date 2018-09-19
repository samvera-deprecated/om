require 'equivalent-xml/rspec_matchers'
require 'logger'
require 'om'
require 'pry-byebug'
require 'rspec'
require 'samples'

def coverage_needed?
  ENV['COVERAGE'] || ENV['TRAVIS']
end

if coverage_needed?
  require 'simplecov'
  require 'coveralls'
  SimpleCov.root(File.expand_path('../..', __FILE__))
  SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new(
    [
      SimpleCov::Formatter::HTMLFormatter,
      Coveralls::SimpleCov::Formatter
    ]
  )
  SimpleCov.start('rails') do
    add_filter '/devel'
    add_filter '/lib/om/version.rb'
    add_filter '/lib/tasks'
    add_filter '/spec'
  end
end

OM.logger = Logger.new(STDERR)

RSpec.configure do |config|
  config.full_backtrace = true if ENV['TRAVIS']
  #config.fixture_path = File.expand_path("../fixtures", __FILE__)
end

def fixture(file)
  File.new(File.join(File.dirname(__FILE__), 'fixtures', file))
end
