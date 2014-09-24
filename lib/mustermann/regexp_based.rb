# -*- encoding: utf-8 -*-
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
    def initialize(string, options = {})
      super
      @regexp = compile(options)
    end

    extend Forwardable
    def_delegators :regexp, :===, :=~, :match, :names, :named_captures

    def compile(options = {})
      raise NotImplementedError, 'subclass responsibility'
    end

    private :compile
  end
end
