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
  class Template < AST::Pattern
    on ?{ do |char|
      variable = proc do
        match  = expect(/(?<name>\w+)(?:\:(?<prefix>\d{1,4})|(?<explode>\*))?/)
        node(:variable, match[:name], prefix: match[:prefix], explode: match[:explode])
      end

      operator   = buffer.scan(/[\+\#\.\/;\?\&\=\,\!\@\|]/)
      expression = node(:expression, variable[], operator: operator) { variable[] if scan(?,) }
      expression if expect(?})
    end

    on(?}) { |c| unexpected(c) }
    on(?/) { |c| node(:separator, ?/)}

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

    private :compile, :map_param, :always_array?
  end
end
