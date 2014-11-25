$:.unshift File.expand_path("../../mustermann/lib", __FILE__)
$:.unshift File.expand_path("../../support/lib", __FILE__)

require "mustermann/version"
require "support/projects"

Gem::Specification.new do |s|
  s.name                  = "mustermann-everything"
  s.version               = Mustermann::VERSION
  s.author                = "Konstantin Haase"
  s.email                 = "konstantin.mailinglists@googlemail.com"
  s.homepage              = "https://github.com/rkh/mustermann"
  s.summary               = %q{The complete Mustermann}
  s.description           = %q{Meta gem depending on all official Mustermann gems}
  s.license               = 'MIT'
  s.required_ruby_version = '>= 2.1.0'

  Support::Projects.each do |project|
    next if project == s.name
    s.add_dependency(project, Mustermann::VERSION)
  end
end
