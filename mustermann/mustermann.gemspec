$:.unshift File.expand_path("../lib", __FILE__)
require "mustermann/version"

Gem::Specification.new do |s|
  s.name                  = "mustermann"
  s.version               = Mustermann::VERSION
  s.authors               = ["Konstantin Haase", "Zachary Scott"]
  s.email                 = "sinatrarb@googlegroups.com"
  s.homepage              = "https://github.com/sinatra/mustermann"
  s.summary               = %q{Your personal string matching expert.}
  s.description           = %q{A library implementing patterns that behave like regular expressions.}
  s.license               = 'MIT'
  s.required_ruby_version = '>= 2.7.0'
  s.files                 = `git ls-files lib`.split("\n") + ['LICENSE', 'README.md']
end
