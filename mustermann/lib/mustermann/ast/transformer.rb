require 'mustermann/ast/translator'

module Mustermann
  module AST
    # Takes a tree, turns it into an even better tree.
    # @!visibility private
    class Transformer < Translator

      # Transforms a tree.
      # @note might mutate handed in tree instead of creating a new one
      # @param [Mustermann::AST::Node] tree to be transformed
      # @return [Mustermann::AST::Node] transformed tree
      # @!visibility private
      def self.transform(tree)
        new.translate(tree)
      end

      translate(:node) { self }
      translate(:group, :root) do
        self.payload = t(payload)
        self
      end

      # URI expression transformations depending on operator
      # @!visibility private
      class ExpressionTransform < NodeTranslator
        register :expression

        # @!visibility private
        Operator  ||= Struct.new(:separator, :allow_reserved, :prefix, :parametric)

        # Operators available for expressions.
        # @!visibility private
        OPERATORS ||= {
          nil => Operator.new(?,, false, false, false), ?+  => Operator.new(?,, true,  false, false),
          ?#  => Operator.new(?,, true,  ?#,    false), ?.  => Operator.new(?., false, ?.,    false),
          ?/  => Operator.new(?/, false, ?/,    false), ?;  => Operator.new(?;, false, ?;,    true),
          ??  => Operator.new(?&, false, ??,    true),  ?&  => Operator.new(?&, false, ?&,    true)
        }

        # Sets operator and inserts separators in between variables.
        # @!visibility private
        def translate
          self.operator = OPERATORS.fetch(operator) { raise CompileError, "#{operator} operator not supported" }
          separator     = Node[:separator].new(operator.separator)
          prefix        = Node[:separator].new(operator.prefix)
          self.payload  = Array(payload.inject { |list, element| Array(list) << t(separator.dup) << t(element) })
          payload.unshift(prefix) if operator.prefix
          self
        end
      end

      # Inserts with_look_ahead nodes wherever appropriate
      # @!visibility private
      class ArrayTransform < NodeTranslator
        register Array

        # the new array
        # @!visibility private
        def payload
          @payload ||= []
        end

        # buffer for potential look ahead
        # @!visibility private
        def lookahead_buffer
          @lookahead_buffer ||= []
        end

        # transform the array
        # @!visibility private
        def translate
          each { |e| track t(e) }
          payload.concat create_lookahead(lookahead_buffer, true)
        end

        # handle a single element from the array
        # @!visibility private
        def track(element)
          return list_for(element) << element if lookahead_buffer.empty?
          return lookahead_buffer  << element if lookahead? element

          lookahead = lookahead_buffer.dup
          lookahead = create_lookahead(lookahead, false) if element.is_a? Node[:separator]
          lookahead_buffer.clear

          payload.concat(lookahead) << element
        end

        # turn look ahead buffer into look ahead node
        # @!visibility private
        def create_lookahead(elements, *args)
          return elements unless elements.size > 1
          [Node[:with_look_ahead].new(elements, *args)]
        end

        # can the given element be used in a look-ahead?
        # @!visibility private
        def lookahead?(element, in_lookahead = false)
          case element
          when Node[:char]     then in_lookahead
          when Node[:group]    then lookahead_payload?(element.payload, in_lookahead)
          when Node[:optional] then lookahead?(element.payload, true) or expect_lookahead?(element.payload)
          end
        end

        # does the list of elements look look-ahead-ish to you?
        # @!visibility private
        def lookahead_payload?(payload, in_lookahead)
          return unless payload[0..-2].all? { |e| lookahead?(e, in_lookahead) }
          expect_lookahead?(payload.last) or lookahead?(payload.last, in_lookahead)
        end

        # can the current element deal with a look-ahead?
        # @!visibility private
        def expect_lookahead?(element)
          return element.class == Node[:capture] unless element.is_a? Node[:group]
          element.payload.all? { |e| expect_lookahead?(e) }
        end

        # helper method for deciding where to put an element for now
        # @!visibility private
        def list_for(element)
          expect_lookahead?(element) ? lookahead_buffer : payload
        end
      end
    end
  end
end
