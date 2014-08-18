if RUBY_VERSION < '2.0.0'
  $stderr.puts "needs Ruby 2.0.0, you're running #{RUBY_VERSION}"
  exit 1
end

ENV['RACK_ENV'] = 'test'

require 'rspec'
require 'rspec/its'

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = [:should, :expect]
  end
end
