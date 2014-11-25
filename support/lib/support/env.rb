if RUBY_VERSION < '2.1.0'
  $stderr.puts "needs Ruby 2.1.0, you're running #{RUBY_VERSION}"
  exit 1
end

RUBY_ENGINE ||= 'ruby'
ENV['RACK_ENV'] = 'test'

require 'tool/warning_filter'
$-w = true

require 'rspec'
require 'rspec/its'

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = [:should, :expect]
  end
end
