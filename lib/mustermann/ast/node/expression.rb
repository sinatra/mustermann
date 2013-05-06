require 'mustermann/ast/node'

module Mustermann
  module AST
    class Node
      # AST node for template expressions.
      # @!visibility private
      class Expression < Group
        Operator  ||= Struct.new(:separator, :allow_reserved, :prefix, :parametric)
        OPERATORS ||= {
          nil => Operator.new(?,, false, false, false), ?+  => Operator.new(?,, true,  false, false),
          ?#  => Operator.new(?,, true,  ?#,    false), ?.  => Operator.new(?., false, ?.,    false),
          ?/  => Operator.new(?/, false, ?/,    false), ?;  => Operator.new(?;, false, ?;,    true),
          ??  => Operator.new(?&, false, ??,    true),  ?&  => Operator.new(?&, false, ?&,    true)
        }

        # @!visibility private
        attr_accessor :operator

        # makes sure we have the proper surrounding characters for the operator
        # @!visibility private
        def transform
          self.operator = OPERATORS.fetch(operator) { raise CompileError, "#{operator} operator not supported" }
          new_payload   = payload.inject { |list, element| Array(list) << separator << element }
          @payload      = Array(new_payload).map!(&:transform)
          payload.unshift separator(operator.prefix) if operator.prefix
          self
        end

        # @!visibility private
        def compile(greedy: true, **options)
          super(allow_reserved: operator.allow_reserved, greedy: greedy && !operator.allow_reserved,
            parametric: operator.parametric, separator: operator.separator, **options)
        end

        # @!visibility private
        def separator(char = operator.separator)
          Separator.new(char)
        end
      end
    end
  end
end
