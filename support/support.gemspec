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
  s.files        = `git ls-files`.split("\n")
  s.test_files   = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables  = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }

  s.add_dependency 'tool', '~> 0.2'
  s.add_dependency 'rspec'
  s.add_dependency 'rspec-its'
  s.add_dependency 'addressable'
  s.add_dependency 'sinatra', '~> 1.4'
  s.add_dependency 'rack-test'
  s.add_dependency 'rake'
  s.add_dependency 'yard'
  s.add_dependency 'simplecov'
  s.add_dependency 'coveralls'
end
