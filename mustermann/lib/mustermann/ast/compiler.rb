# frozen_string_literal: true

require 'mustermann/ast/translator'

module Mustermann
  # @see Mustermann::AST::Pattern
  module AST
    # Regexp compilation logic.
    # @!visibility private
    class Compiler < Translator
      raises CompileError

      # Compile an array of AST nodes, detecting which captures can safely use
      # atomic groups.  A capture is safe to atomicize when its very next sibling
      # is a *path separator* (payload '/'), because every Mustermann capture
      # character class (Sinatra's [^\/\?#]+, Template's [\w\-\.~%]+, etc.)
      # excludes '/', so the greedy match naturally stops before '/' and
      # committing to it atomically never affects correctness.
      #
      # More permissive conditions (e.g. end-of-array) are intentionally avoided:
      # template expressions nest captures inside inner arrays where end-of-array
      # does NOT mean end-of-pattern, and non-'/' separators (e.g. '.' in
      # {.a,b,c}) may appear inside the capture character class.
      #
      # Splats (.*?) and non-greedy captures are excluded — atomicizing them
      # would commit to zero or one character and break match resolution.
      # Strip `atomic:` from incoming options so a parent's value cannot bleed
      # into siblings; each element's atomicity comes solely from its own context.
      translate(Array) do |atomic: false, **options|
        greedy = options.fetch(:greedy, true)
        each_with_index.map do |element, index|
          next_sibling = self[index + 1]
          atomic = greedy &&
            element.is_a?(:capture) &&
            !element.is_a?(:splat) &&
            next_sibling&.is_a?(:separator) &&
            next_sibling.payload == '/'
          t(element, **options, atomic: atomic)
        end.join
      end

      translate(:node)      { |**o| t(payload, **o)             }
      translate(:separator) { |**o| Regexp.escape(payload)      }
      translate(:optional)  { |**o| '(?:%s)?' % t(payload, **o) }
      translate(:char)      { |**o| t.encoded(payload, **o)     }

      translate :union do |**options|
        '(?:%s)' % payload.map { |e| '(?:%s)' % t(e, **options) }.join('|')
      end

      translate :expression do |greedy: true, **options|
        t(payload, allow_reserved: operator.allow_reserved, greedy: greedy && !operator.allow_reserved,
                   parametric: operator.parametric, separator: operator.separator, **options)
      end

      translate :with_look_ahead do |atomic: false, **options|
        greedy = options.fetch(:greedy, true)
        lookahead = each_leaf.inject('') do |ahead, element|
          ahead + t(element, skip_optional: true, lookahead: ahead, greedy: false, no_captures: true, **options).to_s
        end
        lookahead << (at_end ? '$' : '/')
        # The look-ahead already constrains what the head capture can match, so
        # it is safe to make it atomic when greedy.  Non-greedy captures rely on
        # backtracking to extend their match and must not be committed atomically.
        t(head, **options, lookahead: lookahead, atomic: greedy) + t(payload, **options)
      end

      # Capture compilation is complex. :(
      # @!visibility private
      class Capture < NodeTranslator
        register :capture

        # @!visibility private
        # When +atomic: true+ is passed (set by the Array translator for captures
        # that are followed only by a separator or end-of-pattern), the compiled
        # content is wrapped in an atomic group <tt>(?>…)</tt>.  This prevents
        # Oniguruma from backtracking into characters the capture has already
        # consumed, giving a measurable speedup on failing matches without
        # changing the result for any valid input.
        def translate(atomic: false, **options)
          return pattern(**options) if options[:no_captures]

          inner = translate(no_captures: true, **options)
          # Atomic groups are only safe for pure character-class repetitions.
          # Captures with an explicit array/hash/string option or a custom
          # constraint produce alternations that need backtracking to resolve
          # the correct alternative, so they must not be wrapped atomically.
          apply_atomic = atomic && options[:capture].nil? && constraint.nil?
          content = apply_atomic ? "(?>#{inner})" : inner
          "(?<#{name}>#{content})"
        end

        # @return [String] regexp without the named capture
        # @!visibility private
        def pattern(capture: nil, **options)
          case capture
          when Symbol then from_symbol(capture, **options)
          when Array  then from_array(capture, **options)
          when Hash   then from_hash(capture, **options)
          when String then from_string(capture, **options)
          when nil    then from_nil(**options)
          else capture
          end
        end

        private

        def qualified(string, greedy: true,
                      **options) "#{string}#{qualifier || "+#{'?' unless greedy}"}"
        end

        def with_lookahead(string, lookahead: nil,
                           **options) lookahead ? "(?:(?!#{lookahead})#{string})" : string
        end

        def from_hash(hash,
                      **options) pattern(capture: hash[name.to_sym],
                                         **options)
        end

        def from_array(array, **options)
          Regexp.union(*array.map do |e|
            pattern(capture: e, **options)
          end)
        end

        def from_symbol(symbol,
                        **options) qualified(with_lookahead("[[:#{symbol}:]]", **options),
                                             **options)
        end

        def from_string(string, **options)
          Regexp.new(string.chars.map do |c|
            t.encoded(c, **options)
          end.join)
        end

        def from_nil(**options)
          qualified(
            with_lookahead(default(**options), **options), **options
          )
        end

        def default(**options) = constraint || '[^/\\?#]'
      end

      # @!visibility private
      class Splat < Capture
        register :splat, :named_splat
        # splats are always non-greedy
        # @!visibility private
        def pattern(**options)
          constraint || '.*?'
        end
      end

      # @!visibility private
      class Variable < Capture
        register :variable

        # @!visibility private
        def translate(atomic: false, **options)
          # Exploded variables expand to `pattern(?:sep pattern)*`.  The engine
          # must be able to backtrack through that repetition when a following
          # capture (e.g. the 'b' in {/a*,b}) needs to claim the last segment.
          # Strip `atomic:` so Capture#translate never wraps the repetition.
          effective_atomic = atomic && !explode
          return super(atomic: effective_atomic, **options) if explode or !options[:parametric]

          # Remove this line after fixing broken compatibility between 2.1 and 2.2
          options.delete(:parametric) if options.has_key?(:parametric)
          parametric super(atomic: effective_atomic, parametric: false, **options)
        end

        # @!visibility private
        def pattern(parametric: false, separator: nil, **options)
          register_param(parametric: parametric, separator: separator, **options)
          pattern = super(**options)
          pattern = parametric(pattern) if parametric
          pattern = "#{pattern}(?:#{Regexp.escape(separator)}#{pattern})*" if explode and separator
          pattern
        end

        # @!visibility private
        def parametric(string)
          "#{Regexp.escape(name)}(?:=#{string})?"
        end

        # @!visibility private
        def qualified(string, **options)
          prefix ? "#{string}{1,#{prefix}}" : super(string, **options)
        end

        # @!visibility private
        def default(allow_reserved: false, **options)
          allow_reserved ? '[\w\-\.~%\:/\?#\[\]@\!\$\&\'\(\)\*\+,;=]' : '[\w\-\.~%]'
        end

        # @!visibility private
        def register_param(parametric: false, split_params: nil, separator: nil, **options)
          return unless explode and split_params

          split_params[name] = { separator: separator, parametric: parametric }
        end
      end

      # @return [Array<String>] all raw string representations of the character (literal + URI-encoded variants)
      # @!visibility private
      def self.char_representations(char, uri_decode: true, space_matches_plus: true)
        if char == ' ' and space_matches_plus
          @space_and_plus ||= char_representations(' ', space_matches_plus: false) +
                              char_representations('+', space_matches_plus: false)
        else
          @char_representations ||= {}
          @char_representations[char] ||= begin
            escaped = URI_PARSER.escape(char, /./)
            [char, escaped.upcase, escaped.downcase].uniq
          end
        end
      end

      # @return [String] Regular expression for matching the given character in all representations
      # @!visibility private
      def encoded(char, uri_decode: true, space_matches_plus: true, **options)
        return Regexp.escape(char) unless uri_decode

        '(?:%s)' % self.class.char_representations(char, uri_decode:, space_matches_plus:).map { |c|
          Regexp.escape(c)
        }.join('|')
      end

      # Compiles an AST to a regular expression.
      # @param [Mustermann::AST::Node] ast the tree
      # @return [Regexp] corresponding regular expression.
      #
      # @!visibility private
      def self.compile(ast, **options)
        new.compile(ast, **options)
      end

      # Compiles an AST to a regular expression.
      # @param [Mustermann::AST::Node] ast the tree
      # @return [Regexp] corresponding regular expression.
      #
      # @!visibility private
      def compile(ast, except: nil, **options)
        except &&= "(?!#{translate(except, no_captures: true, **options)}\\Z)"
        Regexp.new("#{except}#{translate(ast, **options)}")
      end
    end

    private_constant :Compiler
  end
end
