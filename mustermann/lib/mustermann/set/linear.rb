# frozen_string_literal: true
require 'mustermann/set/match'

module Mustermann
  class Set
    class Linear
      def initialize(set, patterns = [])
        @set      = set
        @patterns = patterns
      end

      def add(pattern)
        @patterns << pattern
      end

      def match(string, all: false, peek: false)
        result = [] if all
        @patterns.each do |pattern|
          next unless match = peek ? pattern.peek_match(string) : pattern.match(string)
          return Match.new(match:, value: @set.values_for_pattern(pattern)&.first) unless all
          values = @set.values_for_pattern(pattern) || [nil]
          values.each { |value| result << Match.new(match:, value:) }
        end
        result
      end
    end

    private_constant :Linear
  end
end
