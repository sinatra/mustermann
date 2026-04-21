# frozen_string_literal: true

module Mustermann
  module AST
    # Mixin for AST::Pattern subclasses that accelerates compilation and AST
    # construction for "simple" patterns: only static path segments and
    # unconstrained full-segment captures (e.g. /foo/:bar/baz/:id).
    # Patterns with optional groups, constraints, or non-default options fall
    # through to the full AST pipeline.
    module FastPattern
      # Matches patterns that consist only of slashes, static segments, and
      # simple :name captures — no optional groups, no constraints.
      SIMPLE = /\A(?:\/(?:[a-zA-Z0-9\-_.~]+|:[a-zA-Z_]\w*))+\z/

      # Regexp fragment for each printable ASCII char, matching the same output
      # as Compiler#encoded with uri_decode: true.
      ENCODED = (0..127).each_with_object({}) do |byte, h|
        c   = byte.chr
        pct = '%%%02X' % byte
        reps = [c, pct, pct.downcase].uniq
        h[c] = reps.size == 1 ? Regexp.escape(reps.first) :
          '(?:%s)' % reps.map { |r| Regexp.escape(r) }.join('|')
      end.freeze

      SEGMENT_SCAN = %r{(/)|(:[a-zA-Z_]\w*)|([^/:]+)}

      private_constant :SIMPLE, :ENCODED, :SEGMENT_SCAN

      # Bypasses the generic build_match overhead for simple patterns: uses
      # MatchData#named_captures directly and avoids match.to_s / post_match /
      # pre_match calls (all no-ops for \A…\Z anchored regexps).
      def match(string)
        return super unless @fast_match
        return unless match = @regexp.match(string)
        params = match.named_captures
        params.transform_values! { |v| unescape(v) } if string.include?('%')
        Match.new(self, string, params)
      end

      # Public override: fast path for simple patterns, falls through to super otherwise.
      # Must remain public to match AST::Pattern#to_ast visibility.
      def to_ast
        return super unless simple_pattern?
        ast = self.class.ast_cache.fetch(@string) { build_fast_ast }
        @param_converters ||= {}
        ast
      end

      private

      def simple_pattern?
        options[:capture].nil?  &&
          options[:except].nil? &&
          options.fetch(:greedy, true) != false &&
          uri_decode &&
          @string.match?(SIMPLE)
      end

      def compile(**options)
        return super unless simple_pattern?
        result = fast_compile
        @fast_match = true
        result
      end

      def fast_compile
        tokens = @string.scan(SEGMENT_SCAN)
        src = String.new
        tokens.each_with_index do |(sep, cap, chars), i|
          if sep
            src << '\\/'
          elsif cap
            # Mirror the compiler: wrap in atomic group when the next token is a separator.
            if tokens[i + 1]&.first
              src << "(?<#{cap[1..]}>(?>[^/\\?#]+))"
            else
              src << "(?<#{cap[1..]}>[^/\\?#]+)"
            end
          else
            chars.each_char { |c| src << ENCODED[c] }
          end
        end
        Regexp.new(src)
      end

      def build_fast_ast
        nodes = []
        pos   = 0
        @string.scan(SEGMENT_SCAN) do |sep, cap, chars|
          if sep
            node = Node::Separator.new('/')
            node.start, node.stop = pos, pos + 1
            nodes << node
            pos += 1
          elsif cap
            node = Node::Capture.new(cap[1..])
            node.start, node.stop = pos, pos + cap.length
            nodes << node
            pos += cap.length
          else
            chars.each_char do |c|
              node = Node::Char.new(c)
              node.start, node.stop = pos, pos + 1
              nodes << node
              pos += 1
            end
          end
        end
        root = Node::Root.new
        root.payload = nodes
        root.pattern = @string
        root.start, root.stop = 0, @string.length
        root
      end
    end
  end
end
