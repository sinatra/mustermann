# frozen_string_literal: true
require 'mustermann/ast/translator'
require 'mustermann/set/match'

module Mustermann
  class Set
    class Trie
      class Translator < AST::Translator
        translate(:node) { |trie, **o| trie[t.compile(node)] }
        translate(:separator) { |trie, **options| trie[payload] }

        translate(:root) do |trie, **options|
          leaves = t(payload, trie, **options)
          if leaves.is_a? Array
            leaves.each { |leaf| leaf.patterns << t.pattern }
          else
            leaves.patterns << t.pattern
          end
          leaves
        end

        translate(:char) do |trie, **options|
          strings = t.possible_strings(payload)
          return trie if strings.empty?
          primary_node = trie[strings.first]
          strings[1..-1].each { |s| trie.wire(s, primary_node) }
          primary_node
        end

        translate(:optional) do |trie, **options|
          [*t(payload, trie, **options), trie]
        end

        translate(Array) do |trie, **options|
          i = 0
          while i < size
            element = self[i]
            if element.is_a? :char or element.is_a? :separator
              trie = t(element, trie, **options)
              i += 1
            elsif element.is_a? :splat and self[i + 1]&.is_a? :separator
              # Compile splat+separator together so the splat is bounded by the separator,
              # then continue building the trie for the remaining elements.
              trie = trie[t.compile(self[i..i + 1])]
              i += 2
            elsif element.is_a? :splat or !self[i + 1]&.is_a? :separator
              return trie[t.compile(self[i..-1])]
            else
              trie = t(element, trie, **options)
              return trie.flat_map { |node| t(self[i + 1..-1], node, **options) } if trie.is_a? Array
              i += 1
            end
          end
          trie
        end

        attr_reader :pattern

        def initialize(pattern)
          @pattern  = pattern
          @compiler = pattern.compiler.new
          @options  = pattern.options
          super()
        end

        def compile(node, **options) = /\A#{@compiler.translate(node, **@options, **options)}/

        def possible_strings(char)
          return [] if char.empty?
          @compiler.class.char_representations(char, **@options.slice(:uri_decode, :space_matches_plus))
        end
      end

      attr_reader :patterns, :set, :static, :dynamic

      def initialize(set, patterns = [])
        @set      = set
        @patterns = []
        @dynamic  = {}
        @static   = {}
        patterns.each { |pattern| add(pattern) }
      end

      def [](key)
        case key
        when String then @static[key] ||= Trie.new(@set)
        when Regexp then @dynamic[key] ||= Trie.new(@set)
        end
      end

      def wire(string, target)
        return if string.empty?
        if string.size == 1
          @static[string] ||= target
        else
          (@static[string[0]] ||= Trie.new(@set)).wire(string[1..-1], target)
        end
      end

      def match(string, all: false, peek: false, position: 0, params: {})
        return build_matches(string, params, all:) if position >= string.size
        result = [] if all

        if node = @static[string[position]]
          if nested_result = node.match(string, all:, peek:, position: position + 1, params:)
            return nested_result unless all
            result.concat(nested_result)
          end
        end

        anchored = {}
        @dynamic.each do |matcher, node|
          remaining = string[position..-1]
          regexp_match = matcher.match(remaining)
          # Non-greedy patterns (e.g. splat .*?) can match 0 chars on non-empty input, making
          # no progress. Retry with an end-of-string anchor so they consume the full remainder.
          if regexp_match&.to_s&.empty? && !remaining.empty?
            anchored_matcher = anchored[matcher] ||= Regexp.new(matcher.source + '\z')
            regexp_match = anchored_matcher.match(remaining)
          end
          next unless regexp_match

          regexp_match.named_captures.each do |name, value|
            params = params.dup
            params[name] = params[name]&.dup || []
            params[name] << value
          end

          nested_result = node.match(string, all:, params:, peek:, position: position + regexp_match.to_s.size)
          return nested_result unless all
          result.concat(nested_result)
        end

        if peek
          matches = build_matches(string[0, position], params, all:, post_match: string[position..])
          return matches unless all
          result.concat(matches)
        end

        result
      end

      def build_matches(string, params, all: false, **options)
        result = [] if all

        @patterns.each do |pattern|
          pattern_params = params.to_h do |key, value|
            value = value.flat_map { |v| pattern.map_param(key, v) }
            value = value.first if value.size < 2 and not pattern.always_array?(key)
            [key, value]
          end

          values = @set.values_for_pattern(pattern) || [nil]
          values.each do |value|
            match = Set::Match.new(pattern, string, pattern_params, value:, **options)
            return match unless all
            result << match
          end
        end

        result
      end

      def add(pattern)
        Translator.new(pattern).translate(pattern.to_ast, self)
      end
    end

    private_constant :Trie
  end
end
