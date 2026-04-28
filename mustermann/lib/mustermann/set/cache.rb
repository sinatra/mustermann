# frozen_string_literal: true
require 'mustermann/equality_map'

module Mustermann
  class Set
    class Cache
      PLACEHOLDER = Object.new.freeze

      def self.new(matcher) = defined?(ObjectSpace::WeakKeyMap) ? super : matcher

      def initialize(matcher)
        @matcher = matcher
        reset_cache
      end

      def add(pattern)
        @matcher.add(pattern)
        reset_cache
      end

      def match(string, all: false, peek: false)
        cache  = @match_cache[all][peek]
        result = cache[string] ||= @matcher.match(string, all: all, peek: peek) || PLACEHOLDER
        return result unless result.equal? PLACEHOLDER
        all ? EMPTY_ARRAY : nil
      end

      def reset_cache
        @match_cache = {
          true => {
            true => ObjectSpace::WeakKeyMap.new,
            false => ObjectSpace::WeakKeyMap.new
          },
          false => {
            true => ObjectSpace::WeakKeyMap.new,
            false => ObjectSpace::WeakKeyMap.new
          }
        }
      end

      def optimize! = @matcher.optimize!
      def track(...) = @matcher.track(...)
    end

    private_constant :Cache
  end
end
