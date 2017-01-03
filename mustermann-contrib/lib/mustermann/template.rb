# frozen_string_literal: true
require 'mustermann'
require 'mustermann/ast/pattern'

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
    include Concat::Native
    register :template, :uri_template

    on ?{ do |char|
      variable = proc do
        start  = pos
        match  = expect(/(?<name>\w+)(?:\:(?<prefix>\d{1,4})|(?<explode>\*))?/)
        node(:variable, match[:name], prefix: match[:prefix], explode: match[:explode], start: start)
      end

      operator   = buffer.scan(/[\+\#\.\/;\?\&\=\,\!\@\|]/)
      expression = node(:expression, [variable[]], operator: operator) { variable[] if scan(?,) }
      expression if expect(?})
    end

    on(?}) { |c| unexpected(c) }

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

    # Identity patterns support generating templates (the logic is quite complex, though).
    #
    # @example (see Mustermann::Pattern#to_templates)
    # @param (see Mustermann::Pattern#to_templates)
    # @return (see Mustermann::Pattern#to_templates)
    # @see Mustermann::Pattern#to_templates
    def to_templates
      [to_s]
    end

    private :compile, :map_param, :always_array?
  end
end
