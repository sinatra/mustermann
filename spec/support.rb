if RUBY_VERSION < '2.0.0'
  $stderr.puts "needs Ruby 2.0.0, you're running #{RUBY_VERSION}"
  exit 1
end

ENV['RACK_ENV'] = 'test'

require 'simplecov'
require 'coveralls'

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter
]

SimpleCov.start do
  project_name 'mustermann'
  minimum_coverage 100
  coverage_dir '.coverage'

  add_filter "/spec/"
  add_group 'Library', 'lib'
end

RSpec::Matchers.define :match do |expected|
  match do |actual|
    @captures ||= false
    match = actual.match(expected)
    match &&= @captures.all? { |k, v| match[k] == v } if @captures
    match
  end

  chain :capturing do |captures|
    @captures = captures
  end

  failure_message_for_should do |actual|
    require 'pp'
    match = actual.match(expected)
    if match
      key, value = @captures.detect { |k, v| match[k] != v }
      "expected %p to capture %p as %p when matching %p, but got %p\n\nRegular Expression:\n%p" % [
        actual.to_s, key, value, expected, match[key], actual.regexp
      ]
    else
      "expected %p to match %p" % [ actual, expected ]
    end
  end

  failure_message_for_should_not do |actual|
    "expected %p not to match %p" % [
      actual.to_s, expected
    ]
  end
end

RSpec::Matchers.define :expand do |values = {}|
  match do |pattern|
    @string  ||= nil
    begin
      expanded = pattern.expand(values)
    rescue Exception
      false
    else
      @string ? @string == expandend : expandend
    end
  end

  chain :to do |string|
    @string = string
  end

  failure_message_for_should do |pattern|
    message = "expected %p to be expandable with %p" % [pattern, values]
    begin
      expanded = pattern.expand(values)
      message << " and result in %p, but got %p" % [@string, expanded] if @string
    rescue Exception => error
      message << ", but raised %p" % error
    end
    message
  end

  failure_message_for_should_not do |pattern|
    "expected %p not to be expandable with %p" % [pattern, values]
  end
end

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
