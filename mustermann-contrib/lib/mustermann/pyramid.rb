# frozen_string_literal: true
require 'mustermann'
require 'mustermann/ast/pattern'

module Mustermann
  # Pyramid style pattern implementation.
  #
  # @example
  #   Mustermann.new('/<foo>', type: :pryamid) === '/bar' # => true
  #
  # @see Mustermann::Pattern
  # @see file:README.md#pryamid Syntax description in the README
  class Pyramid < AST::Pattern
    register :pyramid

    on(nil, ?}) { |c| unexpected(c) }

    on(?{) do |char|
      name       = expect(/\w+/, char: char)
      constraint = read_brackets(?{, ?}) if scan(?:)
      expect(?}) unless constraint
      node(:capture, name, constraint: constraint)
    end

    on(?*) do |char|
      node(:named_splat, expect(/\w+$/, char: char), convert: -> e { e.split(?/) })
    end
  end
end
