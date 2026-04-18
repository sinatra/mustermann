# frozen_string_literal: true
require 'mustermann/simple_match'

module Mustermann
  class Trie
    class Match
      attr_reader :pattern, :value, :string
      alias_method :to_s, :string

      # @!visibility private
      attr_reader :_captures

      def initialize(pattern, value, string, post_match = "")
        @pattern    = pattern
        @value      = value
        @string     = string
        @post_match = post_match
        @_captures  = {}
      end
    end
  end
end
