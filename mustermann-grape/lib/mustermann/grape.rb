require 'mustermann'
require 'mustermann/ast/pattern'

module Mustermann
  # Grape style pattern implementation.
  #
  # @example
  #   Mustermann.new('/:foo', type: :grape) === '/bar' # => true
  #
  # @see Mustermann::Pattern
  # @see file:README.md#grape Syntax description in the README
  class Grape < AST::Pattern
    register :grape

    on(nil, ??, ?)) { |c| unexpected(c) }

    on(?*)  { |c| scan(/\w+/) ? node(:named_splat, buffer.matched) : node(:splat) }
    on(?:)  { |c| node(:capture, constraint: "[^/\\?#\.]") { scan(/\w+/) } }
    on(?\\) { |c| node(:char, expect(/./)) }
    on(?()  { |c| node(:optional, node(:group) { read unless scan(?)) }) }
    on(?|)  { |c| node(:or) }

    on ?{ do |char|
      type = scan(?+) ? :named_splat : :capture
      name = expect(/[\w\.]+/)
      type = :splat if type == :named_splat and name == 'splat'
      expect(?})
      node(type, name)
    end

    suffix ?? do |char, element|
      node(:optional, element)
    end
  end
end
