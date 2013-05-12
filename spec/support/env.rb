if RUBY_VERSION < '2.0.0'
  $stderr.puts "needs Ruby 2.0.0, you're running #{RUBY_VERSION}"
  exit 1
end

ENV['RACK_ENV'] = 'test'