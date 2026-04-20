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
          return trie if payload.empty?
          trie[payload]
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

        # \G anchors to a position passed to String#match, avoiding substring allocation.
        def compile(node, **options) = /\G#{@compiler.translate(node, **@options, **options)}/
      end

      attr_reader :patterns, :set, :static, :dynamic

      def initialize(set, patterns = [])
        @set             = set
        @patterns        = []
        @dynamic         = {}
        @static          = {}
        @stride          = nil
        @fast_static     = nil
        @byte_lookup     = nil
        @dynamic_entries = nil
        patterns.each { |pattern| add(pattern) }
      end

      def [](key)
        case key
        when String then @static[key] ||= Trie.new(@set)
        when Regexp then @dynamic[key] ||= Trie.new(@set)
        end
      end

      def match(string, all: false, peek: false, position: 0, params: {})
        optimize! if @stride.nil?
        return build_matches(string, params, all:) if position >= string.size
        result = [] if all

        if @fast_static
          stride = @stride
          if node = @fast_static[string[position, stride]]
            if nested_result = node.match(string, all:, peek:, position: position + stride, params:)
              return nested_result unless all
              result.concat(nested_result)
            end
          end
        elsif @byte_lookup
          if node = @byte_lookup[string.getbyte(position)]
            if nested_result = node.match(string, all:, peek:, position: position + 1, params:)
              return nested_result unless all
              result.concat(nested_result)
            end
          end
        end

        unless @dynamic_entries.empty?
          anchored    = nil
          base_params = all ? params : nil
          @dynamic_entries.each do |matcher, node, capture_names, fast_name|
            if fast_name
              # Fast path: unconstrained single-segment capture — no regex, no MatchData.
              end_pos = string.index('/', position) || string.size
              next if end_pos == position
              edge_params = all ? base_params.dup : params
              edge_params[fast_name] = string.byteslice(position, end_pos - position)
              nested_result = node.match(string, all:, params: edge_params, peek:, position: end_pos)
              return nested_result unless all
              result.concat(nested_result)
              next
            end

            regexp_match = matcher.match(string, position)
            # Non-greedy patterns (e.g. splat .*?) can match 0 chars on non-empty input, making
            # no progress. Retry with an end-of-string anchor so they consume the full remainder.
            if regexp_match && regexp_match.end(0) == position
              anchored ||= {}
              anchored_matcher = anchored[matcher] ||= Regexp.new(matcher.source + '\z')
              regexp_match = anchored_matcher.match(string, position)
            end
            next unless regexp_match

            edge_params = all ? base_params.dup : params
            capture_names.each do |name|
              value = regexp_match[name]
              next unless value
              existing = edge_params[name]
              edge_params[name] = existing ? (existing.is_a?(Array) ? existing << value : [existing, value]) : value
            end

            nested_result = node.match(string, all:, params: edge_params, peek:, position: regexp_match.end(0))
            return nested_result unless all
            result.concat(nested_result)
          end
        end

        if peek
          matches = build_matches(string[0, position], params, all:, post_match: string[position..], pre_match: '')
          return matches unless all
          result.concat(matches)
        end

        result
      end

      NIL_VALUES = [nil].freeze

      def build_matches(string, params, all: false, post_match: '', pre_match: '')
        result = [] if all

        @patterns.each do |pattern|
          next if pattern.except_regexp&.match?(string)

          pattern_params = build_pattern_params(pattern, params)

          values = @set.values_for_pattern(pattern) || NIL_VALUES
          values.each do |value|
            match = Set::Match.new(pattern, string, pattern_params, value:, post_match:, pre_match:)
            return match unless all
            result << match
          end
        end

        result
      end

      def build_pattern_params(pattern, params)
        return params if pattern.identity_params?(params)

        result = {}
        params.each do |key, raw|
          if raw.is_a?(Array)
            val = raw.flat_map { |v| pattern.map_param(key, v) }
            val = val.first if val.size < 2 && !pattern.always_array?(key)
          else
            val = pattern.map_param(key, raw)
            val = [val] if pattern.always_array?(key)
          end
          result[key] = val
        end
        result
      end

      def add(pattern)
        @stride          = nil
        @fast_static     = nil
        @byte_lookup     = nil
        @dynamic_entries = nil
        Translator.new(pattern).translate(pattern.to_ast, self)
      end

      # Compacts the trie by replacing sequential single-char static lookups with a
      # single stride-length hash lookup. The stride is the minimum number of static
      # steps all paths from this node share before hitting a dynamic edge or branch.
      def optimize!
        depth = min_static_depth
        if depth > 1
          @fast_static = build_stride_hash(depth)
          @byte_lookup = nil
          @stride      = depth
          @fast_static.each_value(&:optimize!)
        elsif @static.empty?
          @fast_static = nil
          @byte_lookup = nil
          @stride      = 1
          # no children to recurse into
        else
          @fast_static = nil
          @byte_lookup = Array.new(256)
          @static.each { |k, v| @byte_lookup[k.getbyte(0)] = v }
          @stride      = 1
          @static.each_value(&:optimize!)
        end
        @dynamic.each_value(&:optimize!)
        @dynamic_entries = @dynamic.map do |matcher, node|
          names = matcher.names.each(&:freeze)
          # Detect unconstrained single-segment captures: can use fast string.index instead of regex.
          fast = names.size == 1 && matcher.source == "\\G(?<#{names.first}>[^/]+)" ? names.first : nil
          [matcher, node, names, fast]
        end
      end

      protected

      # Returns the minimum number of guaranteed static steps from this node across
      # all possible paths, before encountering a dynamic edge, a terminal pattern,
      # or an empty node. Branching is allowed; only the minimum depth matters.
      def min_static_depth
        return 0 if @dynamic.any?
        return 0 if @patterns.any?
        return 0 if @static.empty?
        1 + @static.values.map { |node| node.min_static_depth }.min
      end

      private

      # Builds a hash whose keys are +stride+-character strings and whose values are
      # the trie nodes reached after consuming exactly those characters.
      def build_stride_hash(stride)
        stride.times.reduce({ "" => self }) do |frontier, _|
          frontier.each_with_object({}) do |(prefix, node), nxt|
            node.static.each { |char, child| nxt[prefix + char] = child }
          end
        end
      end

    end

    private_constant :Trie
  end
end
