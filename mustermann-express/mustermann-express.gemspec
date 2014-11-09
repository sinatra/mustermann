$:.unshift File.expand_path("../../mustermann/lib", __FILE__)
require "mustermann/version"

Gem::Specification.new do |s|
  s.name                  = "mustermann-express"
  s.version               = Mustermann::VERSION
  s.author                = "Konstantin Haase"
  s.email                 = "konstantin.mailinglists@googlemail.com"
  s.homepage              = "https://github.com/rkh/mustermann"
  s.summary               = %q{Express.js syntax for Mustermann}
  s.description           = %q{Adds express.js style patterns to Mustermman}
  s.license               = 'MIT'
  s.required_ruby_version = '>= 2.0.0'
  s.add_dependency 'mustermann', Mustermann::VERSION
end
