source 'https://rubygems.org'
require File.expand_path('../support/lib/support/projects', __FILE__)

path '.' do
  Support::Projects.each { |name| gem(name) }
  gem 'support', group: :development
end

gem 'rake', group: :development

platform :ruby do
  group :development do
    gem 'yard'
    gem 'redcarpet'
    gem 'simplecov'
    gem 'coveralls'
  end
end
