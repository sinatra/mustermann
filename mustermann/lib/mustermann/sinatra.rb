require 'mustermann'
require 'mustermann/ast/pattern'

module Mustermann
  # Sinatra 2.0 style pattern implementation.
  #
  # @example
  #   Mustermann.new('/:foo') === '/bar' # => true
  #
  # @see Mustermann::Pattern
  # @see file:README.md#sinatra Syntax description in the README
  class Sinatra < AST::Pattern
    register :sinatra

    on(nil, ??, ?), ?|) { |c| unexpected(c) }

    on(?*)  { |c| scan(/\w+/) ? node(:named_splat, buffer.matched) : node(:splat) }
    on(?:)  { |c| node(:capture) { scan(/\w+/) } }
    on(?\\) { |c| node(:char, expect(/./)) }

    on ?( do |char|
      groups = []
      groups << node(:group) { read unless check(?)) or scan(?|) } until scan(?))
      groups.size == 1 ? groups.first : node(:union, groups)
    end

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
