require 'mustermann/ast'

module Mustermann
  # Sinatra 2.0 style pattern implementation.
  #
  # @example
  #   Mustermann.new('/:foo') === '/bar' # => true
  #
  # @see Mustermann::Pattern
  # @see file:README.md#sinatra Syntax description in the README
  class Sinatra < AST
    def parse_element(buffer)
      case char = buffer.getch
      when nil, ??, ?) then unexpected(char)
      when ?*          then Splat.new
      when ?/          then Separator.new(char)
      when ?(          then Group.parse { parse_buffer(buffer) unless buffer.scan(/\)/) }
      when ?:          then Capture.parse { buffer.scan(/\w+/) }
      when ?\\         then Char.new expect(buffer, /./)
      else Char.new(char)
      end
    end

    def parse_suffix(element, buffer)
      return element unless buffer.scan(/\?/)
      Optional.new(element)
    end

    private :parse_element, :parse_suffix
  end
end
