$:.unshift File.expand_path("../../mustermann/lib", __FILE__)
require "mustermann/version"

Gem::Specification.new do |s|
  s.name                  = "mustermann-grape"
  s.version               = Mustermann::VERSION
  s.authors               = ["namusyaka", "Konstantin Haase"]
  s.email                 = "namusyaka@gmail.com"
  s.homepage              = "https://github.com/rkh/mustermann"
  s.summary               = %q{Grape syntax for Mustermann}
  s.description           = %q{Adds Grape style patterns to Mustermman}
  s.license               = 'MIT'
  s.required_ruby_version = '>= 2.1.0'
  s.files                 = `git ls-files`.split("\n")
  s.test_files            = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables           = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.add_dependency 'mustermann', Mustermann::VERSION
end
