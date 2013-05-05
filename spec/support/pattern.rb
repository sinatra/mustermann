module Support
  module Pattern
    def pattern(pattern, options = nil, &block)
      description = "pattern %p" % pattern

      if options
        description << " with options %p" % options
        instance = described_class.new(pattern, options)
      else
        instance = described_class.new(pattern)
      end

      context description do
        subject(:pattern) { instance }
        its(:to_s) { should be == pattern }
        its(:inspect) { should be == "#<#{described_class}:#{pattern.inspect}>" }
        its(:names) { should be_an(Array) }

        example 'string should be immune to external change' do
          subject.to_s.replace "NOT THE PATTERN"
          subject.to_s.should be == pattern
        end

        instance_eval(&block)
      end
    end
  end
end