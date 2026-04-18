# frozen_string_literal: true
require 'mustermann/trie/match'

module Mustermann
  class Trie
    class Node
      attr_reader :static, :dynamic, :pattern, :value

      def self.new(matcher = nil, nested = nil, **options)
        case matcher
        when nil    then nested ? nested.merge(super(**options)) : super(**options)
        when Node   then matcher.merge(new(nil, nested, **options))
        when Regexp then super(dynamic: { matcher => new(nil, nested, **options) })
        when String
          return new(nil, nested, **options) if matcher.empty?
          node = new(nil, nested, **options)
          matcher.reverse.each_char { |char| node = new(static: { char => node }) }
          node
        else
          raise TrieError, "unexpected matcher %p" % matcher
        end
      end

      def initialize(static: {}, dynamic: {}, pattern: nil, value: nil)
        @static  = static.dup
        @dynamic = dynamic.dup
        @pattern = pattern
        @value   = value
      end

      def merge(node)
        if pattern and node.pattern
          raise TrieError, "Conflicting patterns %p and %p" % [pattern, node.pattern] if pattern != node.pattern
          raise TrieError, "Conflicting values %p and %p for pattern %p" % [value, node.value, pattern] if value != node.value
        end

        self.class.new(
          static:  static.merge(node.static) { |_, a, b| a.merge(b) },
          dynamic: dynamic.merge(node.dynamic) { |_, a, b| a.merge(b) },
          pattern: pattern.nil? ? node.pattern : pattern,
          value:   value.nil?   ? node.value   : value
        )
      end

      def match(string, peek, position = 0)
        if position >= string.size
          return unless pattern
          return Match.new(pattern, value, string, string.size)
        end

        if node = static[string[position]]
          result = node.match(string, peek, position + 1)
          return result if result
        end

        dynamic.each do |matcher, node|
          debugger if $debug
          next unless regexp_match = matcher.match(string[position..-1])
          next unless trie_match = node.match(string, peek, position + regexp_match.to_s.size) # need to call #to_s here!
          regexp_match.named_captures.each do |name, value|
            trie_match._captures[name] ||= []
            trie_match._captures[name] << value
          end
          return trie_match
        end

        Match.new(pattern, value, string, position) if peek and pattern
      end
    end

    private_constant :Node
  end
end
