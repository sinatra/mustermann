source 'https://rubygems.org'
require File.expand_path('../support/lib/support/projects', __FILE__)

gem 'ruby2_keywords'
path '.' do
  Support::Projects.each { |name| gem(name) }
  gem 'support', group: :development
end

sinatra_version = ENV['sinatra'].to_s
sinatra_version = nil if sinatra_version.empty? || (sinatra_version == 'stable')
sinatra_version = { github: 'sinatra/sinatra' } if sinatra_version == 'head'
gem 'sinatra', sinatra_version
