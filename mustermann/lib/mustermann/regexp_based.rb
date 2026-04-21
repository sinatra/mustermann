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
      @simple_captures = @regexp.named_captures.none? { |name, positions| positions.size > 1 || always_array?(name) }
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

    def match(string)
      return unless match = @regexp.match(string)
      Match.new(self, string, build_params(match))
    end

    extend Forwardable
    def_delegators :regexp, :===, :=~, :names

    private

    def build_match(match)
      return unless match
      Match.new(self, match.to_s, build_params(match), post_match: match.post_match, pre_match: match.pre_match)
    end

    def build_params(match)
      if @simple_captures
        params = match.named_captures
        return params if params.empty? || identity_params?(params)
        params.each_with_object({}) { |(k, v), h| h[k] = map_param(k, v) }
      else
        match.regexp.named_captures.to_h do |name, positions|
          value = positions.size < 2 && !always_array?(name) ? map_param(name, match[name]) :
            positions.flat_map { |pos| map_param(name, match[pos]) }
          [name, value]
        end
      end
    end

    def compile(**options) = raise NotImplementedError, 'subclass responsibility'
  end
end
