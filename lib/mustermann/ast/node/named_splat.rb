require 'mustermann/ast/node'

module Mustermann
  module AST
    class Node
      # @!visibility private
      class NamedSplat < Splat
        # @see Mustermann::AST::Node::Capture#name
        # @!visibility private
        alias_method :name, :payload
      end
    end
  end
end