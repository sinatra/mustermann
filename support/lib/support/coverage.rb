require 'simplecov'
require 'coveralls'
require 'support/projects'

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new(
  [
    SimpleCov::Formatter::HTMLFormatter,
    Coveralls::SimpleCov::Formatter
  ]
)

SimpleCov.start do
  project_name 'mustermann'
  minimum_coverage 100
  coverage_dir '.coverage'

  add_filter "/spec/"
  add_filter "/support/"

  Support::Projects.each do |project|
    add_group project.sub('mustermann-', ''), "/#{project}/lib"
  end
end
