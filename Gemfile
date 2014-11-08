source 'https://rubygems.org'
require File.expand_path('../support/lib/support/projects', __FILE__)

path '.' do
  Support::Projects.each { |name| gem(name) }
  gem 'support', group: :development
end

group :development do
  gem 'rspec'
  gem 'rspec-its'
  gem 'addressable'
  gem 'sinatra', '~> 1.4'
  gem 'rack-test'
  gem 'rake'
  gem 'yard'
  gem 'redcarpet'
  gem 'simplecov'
  gem 'coveralls'
end
