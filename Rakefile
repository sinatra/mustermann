# frozen_string_literal: true

require 'bundler/setup'
require 'support/projects'
require 'mustermann/version'

desc 'Run rspec'
task(:rspec)     { ruby '-S rspec'      }

desc 'Run "yard stats"'
task(:doc_stats) { ruby '-S yard stats' }

task default: [:rspec, :doc_stats]

desc 'Build the gems'
task :pkg do
  rm_rf 'pkg'
  mkdir 'pkg'

  Support::Projects.each do |project|
    cd project do
      ruby "-S gem build #{project}.gemspec"
      mv "#{project}-#{Mustermann::VERSION}.gem", '../pkg/'
    end
  end
end

desc 'Push the gems'
task release: :pkg do
  cd 'pkg' do
    Support::Projects.each do |project|
      ruby "-S gem push #{project}-#{Mustermann::VERSION}.gem"
    end
  end
end

desc 'List projects'
task :list do
  puts "Listing mustermann project..."
  Support::Projects.each do |project|
    puts "#{project} VERSION: #{Mustermann::VERSION}"
  end
end
