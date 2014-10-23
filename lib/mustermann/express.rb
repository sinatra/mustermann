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
    on(nil, ??, ?+, ?*, ?)) { |c| unexpected(c) }
    on(?:) { |c| node(:capture) { scan(/\w+/) } }

    on(?() do |char|
      match = expect(/(?<constraint> [^\(\)]+ ) \)/x, char: char)
      node(:splat, constraint: match[:constraint])
    end

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

    suffix /\( (?<constraint> [^\(\)]+ ) \)/x, after: :capture do |match, element|
      element.constraint = match[:constraint]
      element
    end
  end
end
