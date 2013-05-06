require 'mustermann/ast/node'

module Mustermann
  module AST
    class Node
      # @!visibility private
      class WithLookAhead < Node
        # @!visibility private
        attr_accessor :head, :at_end

        # @!visibility private
        def initialize(payload, at_end)
          self.head, *self.payload = payload
          self.at_end              = at_end
        end

        # @see Mustermann::AST::Node#compile
        # @!visibility private
        def compile(options)
          lookahead = payload.inject('') { |l,e| e.lookahead(l, options) }
          lookahead << (at_end ? '$' : '/')
          head.compile(lookahead: lookahead, **options) + super
        end

        def expand(values)
          head.expand(values) + super
        end
      end
    end
  end
end
