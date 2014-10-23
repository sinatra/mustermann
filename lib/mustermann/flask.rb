require 'mustermann/ast/pattern'

module Mustermann
  # Flask style pattern implementation.
  #
  # @example
  #   Mustermann.new('/<foo?', type: :flask) === '/bar' # => true
  #
  # @see Mustermann::Pattern
  # @see file:README.md#flask Syntax description in the README
  class Flask < AST::Pattern
    on(nil, ?>, ?:) { |c| unexpected(c) }

    on ?< do |char|
      match = expect(/(?:(?<converter>\w+):)?(?<name>\w+)>/, char: char)
      case match[:converter]
      when nil, 'string'   then node(:capture, match[:name])
      when 'int'           then node(:capture, match[:name], constraint: /\d+/,       convert: -> i { Integer(i) })
      when 'float'         then node(:capture, match[:name], constraint: /\d*\.?\d+/, convert: -> f { Float(f)   })
      when 'path'          then node(:named_splat, match[:name])
      else unexpected("converter %p" % match[:converter])
      end
    end
  end
end
