task(:rspec)     { ruby '-S rspec'      }
task(:doc_stats) { ruby '-S yard stats' }
task default: [:rspec, :doc_stats]

task :pkg do
  require 'bundler/setup'
  require 'support/projects'
  require 'mustermann/version'

  rm_rf 'pkg'
  mkdir 'pkg'

  Support::Projects.each do |project|
    cd project do
      ruby "-S gem build #{project}.gemspec"
      mv "#{project}-#{Mustermann::VERSION}.gem", '../pkg/'
    end
  end
end

task release: :pkg do
  cd 'pkg' do
    Support::Projects.each do |project|
      ruby "-S gem push #{project}-#{Mustermann::VERSION}.gem"
    end
  end
end
