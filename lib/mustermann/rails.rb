require 'mustermann/ast'

module Mustermann
  # Rails style pattern implementation.
  #
  # @example
  #   Mustermann.new('/:foo', type: :rails) === '/bar' # => true
  #
  # @see Pattern
  # @see file:README.md#rails Syntax description in the README
  class Rails < AST
    def parse_element(buffer)
      case char = buffer.getch
      when nil then unexpected("end of string")
      when ?)  then unexpected(char, exception: UnexpectedClosingGroup)
      when ?*  then NamedSplat.parse { buffer.scan(/\w+/) }
      when ?/  then Separator.new(char)
      when ?(  then Optional.new(Group.parse { parse_buffer(buffer) })
      when ?:  then Capture.parse { buffer.scan(/\w+/) }
      else Char.new(char)
      end
    end

    private :parse_element
  end
end
