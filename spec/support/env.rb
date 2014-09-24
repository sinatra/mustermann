#if RUBY_VERSION < '2.0.0'
#  $stderr.puts "needs Ruby 2.0.0, you're running #{RUBY_VERSION}"
#  exit 1
#end
require 'rspec'
require 'rspec/its'

ENV['RACK_ENV'] = 'test'

RSpec.configure do |config|
  config.filter_run_excluding :skip => true
  config.expect_with :rspec do |c|
    c.syntax = [:should, :expect]
  end
end
