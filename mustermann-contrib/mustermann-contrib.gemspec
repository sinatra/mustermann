$:.unshift File.expand_path("../../mustermann/lib", __FILE__)
require "mustermann/version"

github = "https://github.com/sinatra/mustermann"

Gem::Specification.new do |s|
  s.name                  = "mustermann-contrib"
  s.version               = Mustermann::VERSION
  s.authors               = ["Konstantin Haase", "Kunpei Sakai", "Patrik Ragnarsson", "Jordan Owens", "Zachary Scott"]
  s.email                 = "sinatrarb@googlegroups.com"
  s.homepage              = github
  s.summary               = %q{Collection of extensions for Mustermann}
  s.description           = %q{Adds many plugins to Mustermann}
  s.license               = 'MIT'
  s.required_ruby_version = '>= 3.3.0'
  s.files                 = `git ls-files lib`.split("\n") + ['LICENSE', 'README.md']

  s.metadata = {
    "bug_tracker_uri"   => "#{github}/issues",
    "changelog_uri"     => "#{github}/blob/main/CHANGELOG.md",
    "documentation_uri" => "#{github}/tree/main/mustermann-contrib#readme",
    "source_code_uri"   => "#{github}/tree/main/mustermann-contrib",
  }

  s.add_dependency 'mustermann', Mustermann::VERSION
  s.add_dependency 'hansi', '~> 0.2.0'
end
