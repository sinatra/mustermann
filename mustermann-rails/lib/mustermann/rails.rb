require 'mustermann'
require 'mustermann/ast/pattern'

module Mustermann
  # Rails style pattern implementation.
  #
  # @example
  #   Mustermann.new('/:foo', type: :rails) === '/bar' # => true
  #
  # @see Mustermann::Pattern
  # @see file:README.md#rails Syntax description in the README
  class Rails < AST::Pattern
    register :rails

    on(nil, ?)) { |c| unexpected(c) }
    on(?*)      { |c| node(:named_splat) { scan(/\w+/) } }
    on(?()      { |c| node(:optional, node(:group) { read unless scan(?)) }) }
    on(?:)      { |c| node(:capture) { scan(/\w+/) } }
  end
end
