require 'mustermann/ast/node'

module Mustermann
  module AST
    class Node
      # @!visibility private
      class Splat < Capture
        # @see Mustermann::AST::Node#expect_lookahead?
        # @!visibility private
        def expect_lookahead?
          false
        end

        # @see Mustermann::AST::Node::Capture#name
        # @!visibility private
        def name
          "splat"
        end

        # @see Mustermann::AST::Node::Capture#pattern
        # @!visibility private
        def pattern(**options)
          ".*?"
        end

        def expand(values)
          values[name.to_sym] ||= ""
          super
        end
      end
    end
  end
end
