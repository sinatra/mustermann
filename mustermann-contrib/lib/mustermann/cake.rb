# frozen_string_literal: true
require 'mustermann'
require 'mustermann/ast/pattern'

module Mustermann
  # CakePHP style pattern implementation.
  #
  # @example
  #   Mustermann.new('/:foo', type: :cake) === '/bar' # => true
  #
  # @see Mustermann::Pattern
  # @see file:README.md#cake Syntax description in the README
  class Cake < AST::Pattern
    register :cake

    on(?:) { |c| node(:capture) { scan(/\w+/) } }
    on(?*) { |c| node(:splat, convert: (-> e { e.split('/') } unless scan(?*))) }
  end
end
