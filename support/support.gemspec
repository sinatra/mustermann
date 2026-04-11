$:.unshift File.expand_path("../../mustermann/lib", __FILE__)
require "mustermann/version"

Gem::Specification.new do |s|
  s.name         = "support"
  s.version      = "0.0.1"
  s.author       = "Konstantin Haase"
  s.email        = "konstantin.mailinglists@googlemail.com"
  s.homepage     = "https://github.com/rkh/mustermann"
  s.summary      = %q{support for mustermann development}
  s.require_path = 'lib'
  s.files        = `git ls-files lib`.split("\n")

  s.add_dependency 'tool', '~> 0.2'
  s.add_dependency 'rspec'
  s.add_dependency 'rspec-its'
  s.add_dependency 'addressable'
  s.add_dependency 'sinatra'
  s.add_dependency 'rack-test'
  s.add_dependency 'rake'
  s.add_dependency 'yard'
  s.add_dependency 'simplecov', '~> 0.17.0'
  s.add_dependency 'irb'
end
