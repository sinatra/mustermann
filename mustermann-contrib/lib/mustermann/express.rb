# frozen_string_literal: true
require 'mustermann'
require 'mustermann/ast/pattern'

module Mustermann
  # Express style pattern implementation.
  #
  # @example
  #   Mustermann.new('/:foo', type: :express) === '/bar' # => true
  #
  # @see Mustermann::Pattern
  # @see file:README.md#flask Syntax description in the README
  class Express < AST::Pattern
    register :express

    on(nil, ??, ?+, ?*, ?)) { |c| unexpected(c) }
    on(?:) { |c| node(:capture) { scan(/\w+/) } }
    on(?() { |c| node(:splat, constraint: read_brackets(?(, ?))) }

    suffix ??, after: :capture do |char, element|
      unexpected(char) unless element.is_a? :capture
      node(:optional, element)
    end

    suffix ?*, after: :capture do |match, element|
      node(:named_splat, element.name)
    end

    suffix ?+, after: :capture do |match, element|
      node(:named_splat, element.name, constraint: ".+")
    end

    suffix ?(, after: :capture do |match, element|
      element.constraint = read_brackets(?(, ?))
      element
    end
  end
end
