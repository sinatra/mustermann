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

        translate(:or) do |trie, **options|
          payload.flat_map { |e| t(e, trie, **options) }
        end

        translate(Array) do |trie, **options|
          each_with_index do |element, index|
            if element.is_a? :char or element.is_a? :separator
              trie = t(element, trie, **options)
            elsif element.is_a? :splat or !self[index + 1]&.is_a? :separator
              return trie[t.compile(self[index..-1])]
            else
              trie = t(element, trie, **options)
              return trie.flat_map { |t| t(self[index + 1..-1], **options) } if trie.is_a? Array
            end
            trie
          end
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
        when String
          case key.size
          when 0 then self
          when 1 then @static[key] ||= Trie.new(@set)
          else self[key[0]][key[1..-1]]
          end
        when Regexp
          @dynamic[key] ||= Trie.new(@set)
        else
          raise ArgumentError, "Only String and Regexp keys are supported, but %p was given" % key
        end
      end

      def wire(string, target)
        return if string.empty?
        if string.size == 1
          existing = @static[string]
          if existing.nil?
            @static[string] = target
          elsif !existing.equal?(target)
            existing.merge!(target)
          end
        else
          (@static[string[0]] ||= Trie.new(@set)).wire(string[1..-1], target)
        end
      end

      def match(string, all: false, peek: false, position: 0, params: {})
        return build_matches(string, params, all:) if position >= string.size
        result = [] if all

        if node = @static[string[position]]
          if nested_result = node.match(string, all: false, peek:, position: position + 1, params:)
            return nested_result unless all
            result.concat(nested_result)
          end
        end

        @dynamic.each do |matcher, node|
          next unless regexp_match = matcher.match(string[position..-1])

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
          matches = build_matches(string, params, all:, post_match: string[position..-1])
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

      def merge!(other)
        return if equal?(other)
        other.patterns.each { |p| @patterns << p unless @patterns.include?(p) }
        other.static.each  { |k, v| wire(k, v) }
        other.dynamic.each { |matcher, v| (@dynamic[matcher] ||= Trie.new(@set)).merge!(v) }
      end
    end

    private_constant :Trie
  end
end
