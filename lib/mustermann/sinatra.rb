require 'mustermann/ast'

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
    on(?*)          { |c| node(:splat) }
    on(?/)          { |c| node(:separator, c) }
    on(?()          { |c| node(:group) { read unless scan(?)) } }
    on(?:)          { |c| node(:capture) { scan(/\w+/) } }
    on(?\\)         { |c| node(:char, expect(/./)) }

    suffix ?? do |char, element|
      node(:optional, element)
    end
  end
end
