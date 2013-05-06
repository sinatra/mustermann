require 'mustermann/ast/node'

module Mustermann
  module AST
    class Node
      # @!visibility private
      class Char < Node
        # @see Mustermann::AST::Node#compile
        # @!visibility private
        def compile(uri_decode: true, space_matches_plus: true, **options)
          encoded(payload, uri_decode, space_matches_plus)
        end

        # @see Mustermann::AST::Node#lookahead?
        # @!visibility private
        def lookahead?(in_lookahead = false)
          in_lookahead
        end

        # @return [String] regexp to be used in lookahead for semi-greedy capturing
        # @!visibility private
        def lookahead(ahead, options)
          ahead + compile(options)
        end

        def expand(values)
          escape(payload, also_escape: /[\/\?#\&\=]/)
        end
      end
    end
  end
end
