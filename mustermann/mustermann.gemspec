$:.unshift File.expand_path("../lib", __FILE__)
require "mustermann/version"

github = "https://github.com/sinatra/mustermann"

Gem::Specification.new do |s|
  s.name                  = "mustermann"
  s.version               = Mustermann::VERSION
  s.authors               = ["Konstantin Haase", "Kunpei Sakai", "Patrik Ragnarsson", "Jordan Owens", "Zachary Scott"]
  s.email                 = "sinatrarb@googlegroups.com"
  s.homepage              = github
  s.summary               = %q{Your personal string matching expert.}
  s.description           = %q{A library implementing patterns that behave like regular expressions.}
  s.license               = 'MIT'
  s.required_ruby_version = '>= 3.3.0'
  s.files                 = `git ls-files lib`.split("\n") + ['LICENSE', 'README.md']

  s.description = <<~DESC
    Mustermann is your personal string matching expert. As an expert in the field of strings and patterns,
    Mustermann keeps its runtime dependencies to a minimum and is fully covered with specs and documentation.
    
    Given a string pattern, Mustermann will turn it into an object that behaves like a regular expression
    and has comparable performance characteristics.
  DESC

  s.metadata = {
    "bug_tracker_uri"   => "#{github}/issues",
    "changelog_uri"     => "#{github}/blob/main/CHANGELOG.md",
    "documentation_uri" => "#{github}/tree/main/mustermann#readme",
    "source_code_uri"   => "#{github}/tree/main/mustermann",
  }
end
