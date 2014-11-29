require 'mustermann'
require 'mustermann/identity'
require 'mustermann/ast/pattern'

module Mustermann
  # Sinatra 2.0 style pattern implementation.
  #
  # @example
  #   Mustermann.new('/:foo') === '/bar' # => true
  #
  # @see Mustermann::Pattern
  # @see file:README.md#sinatra Syntax description in the README
  class Sinatra < AST::Pattern
    register :sinatra

    on(nil, ??, ?)) { |c| unexpected(c) }

    on(?*)  { |c| scan(/\w+/) ? node(:named_splat, buffer.matched) : node(:splat) }
    on(?:)  { |c| node(:capture) { scan(/\w+/) } }
    on(?\\) { |c| node(:char, expect(/./)) }
    on(?()  { |c| node(:group) { read unless scan(?)) } }
    on(?|)  { |c| node(:or) }

    on ?{ do |char|
      type = scan(?+) ? :named_splat : :capture
      name = expect(/[\w\.]+/)
      type = :splat if type == :named_splat and name == 'splat'
      expect(?})
      node(type, name)
    end

    suffix ?? do |char, element|
      node(:optional, element)
    end

    # Takes a string and espaces any characters that have special meaning for Sinatra patterns.
    #
    # @example
    #   require 'mustermann/sinatra'
    #   Mustermann::Sinatra.escape("/:name") # => "/\\:name"
    #
    # @param [#to_s] string the input string
    # @return [String] the escaped string
    def self.escape(string)
      string.to_s.gsub(/[\?\(\)\*:\\\|\{\}]/) { |c| "\\#{c}" }
    end

    # Tries to convert the given input object to a Sinatra pattern with the given options, without
    # changing its parsing semantics.
    # @return [Mustermann::Sinatra, nil] the converted pattern, if possible
    # @!visibility private
    def self.try_convert(input, **options)
      case input
      when String   then new(escape(input), **options)
      when Identity then new(escape(input), **options) if input.uri_decode == options.fetch(:uri_decode, true)
      when self     then input if input.options == options
      end
    end

    # Creates a pattern that matches any string matching either one of the patterns.
    # If a string is supplied, it is treated as a fully escaped Sinatra pattern.
    #
    # If the other pattern is also a Sintara pattern, it might join the two to a third
    # sinatra pattern instead of generating a composite for efficency reasons.
    #
    # This only happens if the sinatra pattern behaves exactly the same as a composite
    # would in regards to matching, parsing, expanding and template generation.
    #
    # @example
    #   pattern = Mustermann.new('/foo/:name') | Mustermann.new('/:first/:second')
    #   pattern === '/foo/bar' # => true
    #   pattern === '/fox/bar' # => true
    #   pattern === '/foo'     # => false
    #
    # @param [Mustermann::Pattern, String] other the other pattern
    # @return [Mustermann::Pattern] a composite pattern
    # @see Mustermann::Pattern#|
    def |(other)
      return super unless converted = self.class.try_convert(other, **options)
      return super unless converted.names.empty? or names.empty?
      self.class.new(@string + "|" + converted.to_s, **options)
    end
  end
end
