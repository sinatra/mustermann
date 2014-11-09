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
  s.add_dependency 'tool', '~> 0.2'
end
