require 'mustermann/ast/node'

module Mustermann
  module AST
    class Node
      # @!visibility private
      class Optional < Node
        # @return [String] regexp to be used in lookahead for semi-greedy capturing
        # @!visibility private
        def lookahead(ahead, options)
          payload.lookahead(ahead, options)
        end

        # @see Mustermann::AST::Node#compile
        # @!visibility private
        def compile(options)
          "(?:%s)?" % payload.compile(options)
        end

        # @see Mustermann::AST::Node#lookahead?
        # @!visibility private
        def lookahead?(in_lookahead = false)
          payload.lookahead? true or payload.expect_lookahead?
        end

        def expand(values)
          before = values.dup
          super
        rescue ExpandError
          values.replace(before)
          ""
        end
      end
    end
  end
end