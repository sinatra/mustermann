require 'timeout'

module Support
  module Pattern
    extend RSpec::Matchers::DSL

    def pattern(pattern, options = nil, &block)
      description   = "pattern %p" % pattern

      if options
        description << " with options %p" % [options]
        instance = subject_for(pattern, **options)
      else
        instance = subject_for(pattern)
      end

      context description do
        subject(:pattern, &instance)
        its(:to_s) { should be == pattern }
        its(:inspect) { should be == "#<#{described_class}:#{pattern.inspect}>" }
        its(:names) { should be_an(Array) }
        its(:to_templates) { should be == [pattern] } if described_class.name == "Mustermann::Template"

        example 'string should be immune to external change' do
          subject.to_s.replace "NOT THE PATTERN"
          subject.to_s.should be == pattern
        end

        instance_eval(&block)
      end
    end

    def subject_for(pattern, *args, **options)
      instance = Timeout.timeout(1) { described_class.new(pattern, *args, **options) }
      proc { instance }
    rescue Timeout::Error => error
      proc { raise Timeout::Error, "could not compile #{pattern.inspect} in time", error.backtrace }
    rescue Exception => error
      proc { raise error }
    end
  end
end