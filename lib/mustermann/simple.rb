# -*- encoding: utf-8 -*-
require 'mustermann/regexp_based'

module Mustermann
  # Sinatra 1.3 style pattern implementation.
  #
  # @example
  #   Mustermann.new('/:foo', type: :simple) === '/bar' # => true
  #
  # @see Mustermann::Pattern
  # @see file:README.md#simple Syntax description in the README
  class Simple < RegexpBased
    supported_options :greedy, :space_matches_plus

    def compile(options = {})
      greedy             = options.fetch(:greedy, true)
      uri_decode         = options.fetch(:uri_decode, true)
      space_matches_plus = options.fetch(:space_matches_plus, true)
      pattern = @string.gsub(/[^\?\%\\\/\:\*\w]/) { |c| encoded(c, uri_decode, space_matches_plus) }
      pattern.gsub!(/((:\w+)|\*)/) do |match|
        match == "*" ? "(?<splat>.*?)" : "(?<#{$2[1..-1]}>[^/?#]+#{?? unless greedy})"
      end
      /\A#{Regexp.new(pattern)}\Z/
    rescue SyntaxError, RegexpError => error
      type = error.message["invalid group name"] ? CompileError : ParseError
      raise type, error.message, error.backtrace
    end

    def encoded(char, uri_decode, space_matches_plus)
      return Regexp.escape(char) unless uri_decode
      parser  = URI::Parser.new
      encoded = Regexp.union(parser.escape(char), parser.escape(char, /./).downcase, parser.escape(char, /./).upcase)
      encoded = Regexp.union(encoded, encoded('+', true, true)) if space_matches_plus and char == " "
      encoded
    end

    private :compile, :encoded
  end
end
