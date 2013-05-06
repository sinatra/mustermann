require 'mustermann/ast/node'

module Mustermann
  module AST
    class Node
      # @!visibility private
      class Capture < Node
        # @see Mustermann::AST::Node#expect_lookahead?
        # @!visibility private
        def expect_lookahead?
          true
        end

        # @see Mustermann::AST::Node#parse
        # @!visibility private
        def parse
          self.payload ||= ""
          super
        end

        # @see Mustermann::AST::Node#capture_names
        # @!visibility private
        def capture_names
          [name]
        end

        # @return [String] name of the capture
        # @!visibility private
        def name
          raise CompileError, "capture name can't be empty" if payload.nil? or payload.empty?
          raise CompileError, "capture name must start with underscore or lower case letter" unless payload =~ /^[a-z_]/
          raise CompileError, "capture name can't be #{payload}" if payload == "splat" or payload == "captures"
          payload
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

        # @return [String] regexp to be used in lookahead for semi-greedy capturing
        # @!visibility private
        def lookahead(ahead, options)
          ahead + pattern(lookahead: ahead, greedy: false, **options).to_s
        end

        # @see Mustermann::AST::Node#compile
        # @!visibility private
        def compile(options)
          return pattern(options) if options[:no_captures]
          "(?<#{name}>#{compile(no_captures: true, **options)})"
        end

        def expand(values)
          value = values.delete(name.to_sym)
          raise ExpandError, "missing key :#{name}" unless value
          escape(value, also_escape: /(?!#{pattern})./)
        end

        private

          # adds qualifier to a regepx, ie * or *?
          def qualified(string, greedy: true, **options)
            "#{string}+#{?? unless greedy}"
          end

          # default capture if not overridden by config option
          def default(**options)
            "[^/\\?#]"
          end

          # if capture option is not set, qualified default with lookahead
          def from_nil(**options)
            qualified(with_lookahead(default(**options), **options), **options)
          end

          # resolves capture setting depending on name
          def from_hash(hash, **options)
            entry = hash[name.to_sym]
            pattern(capture: entry, **options)
          end

          # creates union of all elements
          def from_array(array, **options)
            array = array.map { |e| pattern(capture: e, **options) }
            Regexp.union(*array)
          end

          # maps symbol to character group
          def from_symbol(symbol, **options)
            qualified(with_lookahead("[[:#{symbol}:]]", **options), **options)
          end

          # direct string matching
          def from_string(string, uri_decode: true, space_matches_plus: true, **options)
            Regexp.new(string.chars.map { |c| encoded(c, uri_decode, space_matches_plus) }.join)
          end

          # adds look-ahead to a regexp string
          def with_lookahead(string, lookahead: nil, **options)
            return string unless lookahead
            "(?:(?!#{lookahead})#{string})"
          end
      end
    end
  end
end