$:.unshift File.expand_path("../../mustermann/lib", __FILE__)
require "mustermann/version"

Gem::Specification.new do |s|
  s.name                  = "mustermann-contrib"
  s.version               = Mustermann::VERSION
  s.authors               = ["Konstantin Haase", "Zachary Scott"]
  s.email                 = "sinatrarb@googlegroups.com"
  s.homepage              = "https://github.com/sinatra/mustermann"
  s.summary               = %q{Collection of extensions for Mustermann}
  s.description           = %q{Adds many plugins to Mustermann}
  s.license               = 'MIT'
  s.required_ruby_version = '>= 2.6.0'
  s.files                 = `git ls-files`.split("\n")
  s.test_files            = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.add_dependency 'mustermann', Mustermann::VERSION
  s.add_dependency 'hansi', '~> 0.2.0'
end
