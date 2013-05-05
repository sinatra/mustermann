require 'mustermann/ast/node'

module Mustermann
  module AST
    class Node
      # @!visibility private
      class Separator < Node
        # @see Mustermann::AST::Node#compile
        # @!visibility private
        def compile(options)
          Regexp.escape(payload)
        end

        # @see Mustermann::AST::Node#separator?
        # @!visibility private
        def separator?
          true
        end
      end
    end
  end
end
