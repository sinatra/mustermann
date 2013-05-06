require 'mustermann/ast/node'

module Mustermann
  module AST
    class Node
      # @!visibility private
      class Group < Node
        # @!visibility private
        def initialize(payload = nil, **options)
          super(Array(payload), **options)
        end

        # @see Mustermann::AST::Node#lookahead?
        # @!visibility private
        def lookahead?(in_lookahead = false)
          return false unless payload[0..-2].all? { |e| e.lookahead? in_lookahead }
          payload.last.expect_lookahead? or payload.last.lookahead? in_lookahead
        end

        # Eliminates single element groups.
        #
        # @see Mustermann::AST::Node#transform
        # @!visibility private
        def transform
          payload.size == 1 ? payload.first.transform : super
        end

        # @return [String] regexp to be used in lookahead for semi-greedy capturing
        # @!visibility private
        def lookahead(ahead, options)
          payload.inject(ahead) { |a,e| e.lookahead(a, options) }
        end
      end
    end
  end
end