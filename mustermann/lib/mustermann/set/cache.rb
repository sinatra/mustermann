# frozen_string_literal: true
require 'mustermann/equality_map'

module Mustermann
  class Set
    class Cache
      PLACEHOLDER = Object.new.freeze

      def self.new(matcher) = defined?(ObjectSpace::WeakKeyMap) ? super : matcher

      def initialize(matcher)
        @matcher     = matcher
        @match_cache = ObjectSpace::WeakKeyMap.new
      end

      def add(pattern)
        @matcher.add(pattern)
        @match_cache = ObjectSpace::WeakKeyMap.new
      end

      def match(string, all: false, peek: false)
        if all || peek
          @matcher.match(string, all:, peek:)
        else
          result = @match_cache[string] ||= @matcher.match(string) || PLACEHOLDER
          result unless result.equal? PLACEHOLDER
        end
      end

      def optimize! = @matcher.optimize!
    end

    private_constant :Cache
  end
end
