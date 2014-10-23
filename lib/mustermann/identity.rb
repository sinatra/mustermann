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

    # @param (see Mustermann::Pattern#peek_size)
    # @return (see Mustermann::Pattern#peek_size)
    # @see (see Mustermann::Pattern#peek_size)
    def peek_size(string)
      return unless unescape(string).start_with? @string
      return @string.size if string.start_with? @string # optimization
      @uri ||= URI::Parser.new
      @string.each_char.with_index.inject(0) do |count, (char, index)|
        char_size = 1
        escaped   = @uri.escape(char, /./)
        char_size = escaped.size if string[index, escaped.size].downcase == escaped.downcase
        count + char_size
      end
    end

    # URI templates support generating templates (the logic is quite complex, though).
    #
    # @example (see Mustermann::Pattern#to_templates)
    # @param (see Mustermann::Pattern#to_templates)
    # @return (see Mustermann::Pattern#to_templates)
    # @see Mustermann::Pattern#to_templates
    def to_templates
      @uri ||= URI::Parser.new
      [@uri.escape(to_s)]
    end
  end
end
