# frozen_string_literal: true
require 'mustermann/pattern'
require 'forwardable'

module Mustermann
  # Superclass for patterns that internally compile to a regular expression.
  # @see Mustermann::Pattern
  # @abstract
  class RegexpBased < Pattern
    # @return [Regexp] regular expression equivalent to the pattern.
    attr_reader :regexp
    alias_method :to_regexp, :regexp

    # @param (see Mustermann::Pattern#initialize)
    # @return (see Mustermann::Pattern#initialize)
    # @see (see Mustermann::Pattern#initialize)
    def initialize(string, **options)
      super
      regexp       = compile(**options)
      @peek_regexp = /\A#{regexp}/
      @regexp      = /\A#{regexp}\Z/
    end

    # @param (see Mustermann::Pattern#peek_size)
    # @return (see Mustermann::Pattern#peek_size)
    # @see (see Mustermann::Pattern#peek_size)
    def peek_size(string)
      return unless match = peek_match(string)
      match.to_s.size
    end

    # @param (see Mustermann::Pattern#peek_match)
    # @return (see Mustermann::Pattern#peek_match)
    # @see (see Mustermann::Pattern#peek_match)
    def peek_match(string) = build_match(@peek_regexp.match(string))

    def match(string) = build_match(@regexp.match(string))

    # private

    # def build_match(match)
    #   return unless match
    #   Match.new(self, match.string, match.named_captures, post_match: match.post_match, pre_match: match.pre_match)
    # end

    extend Forwardable
    def_delegators :regexp, :===, :=~, :names

    private

    def build_match(match)
      return unless match
      params = match.regexp.named_captures.to_h do |name, positions|
        value = positions.size < 2 && !always_array?(name) ? map_param(name, match[name]) :
          positions.flat_map { |pos| map_param(name, match[pos]) }
        [name, value]
      end
      Match.new(self, match.to_s, params, post_match: match.post_match, pre_match: match.pre_match)
    end

    def compile(**options) = raise NotImplementedError, 'subclass responsibility'
  end
end
