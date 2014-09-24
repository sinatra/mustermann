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
    on(nil, ??, ?)) { |c| unexpected(c) }
    on(?*)          { |c| scan(/\w+/) ? node(:named_splat, buffer.matched) : node(:splat) }
    on(?()          { |c| node(:group) { read unless scan(?)) } }
    on(?:)          { |c| node(:capture) { scan(/\w+/) } }
    on(?\\)         { |c| node(:char, expect(/./)) }

    suffix ?? do |char, element|
      node(:optional, element)
    end
  end
end
