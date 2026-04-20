# frozen_string_literal: true
require 'mustermann/equality_map'

module Mustermann
  class Set
    class Cache
      PLACEHOLDER = Object.new.freeze

      def self.new(matcher) = defined?(ObjectSpace::WeakKeyMap) ? super : matcher

      def initialize(matcher)
        @matcher = matcher
        @caches = {}
      end

      def add(pattern)
        @matcher.add(pattern)
        @caches.clear
      end

      def match(string, **options)
        cache  = @caches[options] ||= ObjectSpace::WeakKeyMap.new
        result = cache[string]    ||= @matcher.match(string, **options) || PLACEHOLDER
        result unless result.equal? PLACEHOLDER
      end
    end

    private_constant :Cache
  end
end
