require 'mustermann/ast'

module Mustermann
  # URI template pattern implementation.
  #
  # @example
  #   Mustermann.new('/{foo}') === '/bar' # => true
  #
  # @see Mustermann::Pattern
  # @see file:README.md#template Syntax description in the README
  # @see http://tools.ietf.org/html/rfc6570 RFC 6570
  class Template < AST
    Operator  ||= Struct.new(:separator, :allow_reserved, :prefix, :parametric)
    OPERATORS ||= {
      nil => Operator.new(?,, false, false, false), ?+  => Operator.new(?,, true,  false, false),
      ?#  => Operator.new(?,, true,  ?#,    false), ?.  => Operator.new(?., false, ?.,    false),
      ?/  => Operator.new(?/, false, ?/,    false), ?;  => Operator.new(?;, false, ?;,    true),
      ??  => Operator.new(?&, false, ??,    true),  ?&  => Operator.new(?&, false, ?&,    true)
    }

    # AST node for template expressions.
    # @!visibility private
    class Expression < Group
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
        AST.const_get(:Separator).new(char) # uhm
      end
    end

    # AST node for template variables.
    # @!visibility private
    class Variable < Capture
      # @!visibility private
      attr_accessor :prefix, :explode

      # @!visibility private
      def compile(**options)
        return super(**options) if explode or not options[:parametric]
        parametric super(parametric: false, **options)
      end

      # @!visibility private
      def pattern(parametric: false, **options)
        register_param(parametric: parametric, **options)
        pattern = super(**options)
        pattern = parametric(pattern) if parametric
        pattern = "#{pattern}(?:#{Regexp.escape(options.fetch(:separator))}#{pattern})*" if explode
        pattern
      end

      # @!visibility private
      def parametric(string)
        "#{Regexp.escape(name)}(?:=#{string})?"
      end

      # @!visibility private
      def qualified(string, **options)
        prefix ? "#{string}{1,#{prefix}}" : super(string, **options)
      end

      # @!visibility private
      def default(allow_reserved: false, **options)
        allow_reserved ? '[\w\-\.~%\:/\?#\[\]@\!\$\&\'\(\)\*\+,;=]' : '[\w\-\.~%]'
      end

      # @!visibility private
      def register_param(parametric: false, split_params: nil, separator: nil, **options)
        return unless explode and split_params
        split_params[name] = { separator: separator, parametric: parametric }
      end
    end

    # @!visibility private
    def parse_element(buffer)
      parse_expression(buffer) || parse_literal(buffer)
    end

    # @!visibility private
    def parse_expression(buffer)
      return unless buffer.scan(/\{/)
      operator   = buffer.scan(/[\+\#\.\/;\?\&\=\,\!\@\|]/)
      expression = Expression.new(parse_variable(buffer), operator: operator)
      expression.parse { parse_variable(buffer) if buffer.scan(/,/) }
      expression if expect(buffer, ?})
    end

    # @!visibility private
    def parse_variable(buffer)
      match = expect(buffer, /(?<name>\w+)(?:\:(?<prefix>\d{1,4})|(?<explode>\*))?/)
      Variable.new(match[:name], prefix: match[:prefix], explode: match[:explode])
    end

    # @!visibility private
    def parse_literal(buffer)
      return unless char = buffer.getch
      raise unexpected(?}) if char == ?}
      char == ?/ ? Separator.new('/') : Char.new(char)
    end

    # @!visibility private
    def compile(*args, **options)
      @split_params = {}
      super(*args, split_params: @split_params, **options)
    end

    # @!visibility private
    def map_param(key, value)
      return super unless variable = @split_params[key]
      value = value.split variable[:separator]
      value.map! { |e| e.sub(/\A#{key}=/, '') } if variable[:parametric]
      value.map! { |e| super(key, e) }
    end

    # @!visibility private
    def always_array?(key)
      @split_params.include? key
    end

    private :parse_element, :parse_expression, :parse_literal, :parse_variable, :map_param, :always_array?
  end
end
