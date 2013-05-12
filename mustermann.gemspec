$:.unshift File.expand_path("../lib", __FILE__)
require "mustermann/version"

Gem::Specification.new do |s|
  s.name                  = "mustermann"
  s.version               = Mustermann::VERSION
  s.author                = "Konstantin Haase"
  s.email                 = "konstantin.mailinglists@googlemail.com"
  s.homepage              = "https://github.com/rkh/mustermann"
  s.summary               = %q{use patterns like regular expressions}
  s.description           = %q{library implementing patterns that behave like regular expressions}
  s.license               = 'MIT'
  s.files                 = `git ls-files`.split("\n")
  s.test_files            = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables           = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.extra_rdoc_files      = %w[README.md internals.md]
  s.require_path          = 'lib'
  s.required_ruby_version = '>= 2.0.0'

  s.add_development_dependency 'rspec'
  s.add_development_dependency 'sinatra', '~> 1.4'
  s.add_development_dependency 'rack-test'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'yard'
  s.add_development_dependency 'redcarpet'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'coveralls'
end
