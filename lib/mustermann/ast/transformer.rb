require 'mustermann/ast/translator'

module Mustermann
  module AST
    class Transformer < Translator
      Operator  ||= Struct.new(:separator, :allow_reserved, :prefix, :parametric)
      OPERATORS ||= {
        nil => Operator.new(?,, false, false, false), ?+  => Operator.new(?,, true,  false, false),
        ?#  => Operator.new(?,, true,  ?#,    false), ?.  => Operator.new(?., false, ?.,    false),
        ?/  => Operator.new(?/, false, ?/,    false), ?;  => Operator.new(?;, false, ?;,    true),
        ??  => Operator.new(?&, false, ??,    true),  ?&  => Operator.new(?&, false, ?&,    true)
      }

      def self.transform(ast)
        new.translate(ast)
      end

      translate(:node) { self }

      translate(:expression) do
        self.operator = OPERATORS.fetch(operator) { raise CompileError, "#{operator} operator not supported" }
        separator     = Node[:separator].new(operator.separator)
        prefix        = Node[:separator].new(operator.prefix)
        self.payload  = Array(payload.inject { |list, element| Array(list) << t(separator) << t(element) })
        payload.unshift(prefix) if operator.prefix
        self
      end

      translate(:group, :root) do
        self.payload = t(payload)
        self
      end

      class ArrayTransform < NodeTranslator
        register Array

        def payload
          @payload ||= []
        end

        def lookahead_buffer
          @lookahead_buffer ||= []
        end

        def translate
          each { |e| track t(e) }
          payload.concat create_lookahead(lookahead_buffer, true)
        end

        def track(element)
          return list_for(element) << element if lookahead_buffer.empty?
          return lookahead_buffer  << element if lookahead? element

          lookahead = lookahead_buffer.dup
          lookahead = create_lookahead(lookahead, false) if element.is_a? Node[:separator]
          lookahead_buffer.clear

          payload.concat(lookahead) << element
        end

        def create_lookahead(elements, *args)
          return elements unless elements.size > 1
          [Node[:with_look_ahead].new(elements, *args)]
        end

        def lookahead?(element, in_lookahead = false)
          case element
          when Node[:char]     then in_lookahead
          when Node[:group]    then lookahead_payload?(element.payload, in_lookahead)
          when Node[:optional] then lookahead?(element.payload, true) or expect_lookahead?(element.payload)
          end
        end

        def lookahead_payload?(payload, in_lookahead)
          return unless payload[0..-2].all? { |e| lookahead?(e, in_lookahead) }
          expect_lookahead?(payload.last) or lookahead?(payload.last, in_lookahead)
        end

        def expect_lookahead?(element)
          return element.class == Node[:capture] unless element.is_a? Node[:group]
          element.payload.all? { |e| expect_lookahead?(e) }
        end

        def list_for(element)
          expect_lookahead?(element) ? lookahead_buffer : payload
        end
      end
    end
  end
end
