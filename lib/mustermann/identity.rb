# -*- encoding: utf-8 -*-
require 'mustermann/pattern'

module Mustermann
  # Matches strings that are identical to the pattern.
  #
  # @example
  #   Mustermann.new('/:foo', type: :identity) === '/bar' # => false
  #
  # @see Mustermann::Pattern
  # @see file:README.md#identity Syntax description in the README
  class Identity < Pattern
    # @param (see Mustermann::Pattern#===)
    # @return (see Mustermann::Pattern#===)
    # @see (see Mustermann::Pattern#===)
    def ===(string)
      unescape(string) == @string
    end
  end
end
