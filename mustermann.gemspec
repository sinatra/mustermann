$:.unshift File.expand_path("../lib", __FILE__)
require "mustermann/version"

Gem::Specification.new do |s|
  s.name                  = "mustermann19"
  s.version               = Mustermann::VERSION
  s.authors               = ["Konstantin Haase", "namusyaka"]
  s.email                 = "namusyaka@gmail.com"
  s.homepage              = "https://github.com/namusyaka/mustermann"
  s.summary               = %q{use patterns like regular expressions}
  s.description           = %q{library implementing patterns that behave like regular expressions for use in Ruby 1.9}
  s.license               = 'MIT'
  s.files                 = `git ls-files`.split("\n")
  s.test_files            = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables           = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.extra_rdoc_files      = %w[README.md]
  s.require_path          = 'lib'
  s.required_ruby_version = '>= 1.9.2'

  s.add_dependency 'enumerable-lazy'
  s.add_development_dependency 'rspec' #, '~> 2.14'
  s.add_development_dependency 'rspec-its'
  s.add_development_dependency 'addressable'
  s.add_development_dependency 'sinatra', '~> 1.4'
  s.add_development_dependency 'rack-test'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'yard'
  #s.add_development_dependency 'redcarpet'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'coveralls'
end
