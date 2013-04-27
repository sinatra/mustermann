require 'mustermann/pattern'

module Mustermann
  # Matches strings that are identical to the pattern.
  #
  # @example
  #   Mustermann.new('/:foo', type: :identity) === '/bar' # => false
  #
  # @see Pattern
  # @see file:README.md#identity Syntax description in the README
  class Identity < Pattern
    # @param (see Pattern#===)
    # @return (see Pattern#===)
    # @see (see Pattern#===)
    def ===(string)
      unescape(string) == @string
    end
  end
end
