require 'mustermann/regexp_based'

module Mustermann
  # Regexp pattern implementation.
  #
  # @example
  #   Mustermann.new('/.*', type: :regexp) === '/bar' # => true
  #
  # @see Mustermann::Pattern
  # @see file:README.md#simple Syntax description in the README
  class Regular < RegexpBased
    # @param (see Mustermann::Pattern#initialize)
    # @return (see Mustermann::Pattern#initialize)
    # @see (see Mustermann::Pattern#initialize)
    def initialize(string, **options)
      string = $1 if string.to_s =~ /\A\(\?\-mix\:(.*)\)\Z/ && string.inspect == "/#$1/"
      super(string, **options)
    end

    def compile(**options)
      /\A#{@string}\Z/
    end

    private :compile
  end
end
