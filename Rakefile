ENV['JRUBY_OPTS'] = '--2.0'

task(:spec) { ruby '-w -S rspec' }
task(:doc_stats) { ruby '-S yard stats' }
task(default: [:spec, :doc_stats])
