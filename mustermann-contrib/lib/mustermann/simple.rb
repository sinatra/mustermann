# frozen_string_literal: true
require 'mustermann'
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
    register :simple
    supported_options :greedy, :space_matches_plus
    instance_delegate highlighter: 'self.class'

    # @!visibility private
    # @return [#highlight, nil]
    #   highlighing logic for mustermann-visualizer,
    #   nil if mustermann-visualizer hasn't been loaded
    def self.highlighter
      return unless defined? Mustermann::Visualizer::Highlighter
      @highlighter ||= Mustermann::Visualizer::Highlighter.create do
        on(/:(\w+)/) { |matched| element(:capture, ':') { element(:name, matched[1..-1]) } }
        on("*" => :splat, "?" => :optional)
      end
    end

    def compile(greedy: true, uri_decode: true, space_matches_plus: true, **options)
      pattern = @string.gsub(/[^\?\%\\\/\:\*\w]/) { |c| encoded(c, uri_decode, space_matches_plus) }
      pattern.gsub!(/((:\w+)|\*)/) do |match|
        match == "*" ? "(?<splat>.*?)" : "(?<#{$2[1..-1]}>[^/?#]+#{?? unless greedy})"
      end
      Regexp.new(pattern)
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
