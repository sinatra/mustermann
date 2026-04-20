# frozen_string_literal: true
require 'mustermann/match'

module Mustermann
  class Set
    class Match < Mustermann::Match
      attr_reader :value

      def initialize(pattern = nil, string = nil, params = {}, value: nil, match: nil, post_match: '', pre_match: '')
        @value = value
        if match
          @pattern    = match.pattern
          @string     = match.string
          @params     = match.params
          @post_match = match.post_match
          @pre_match  = match.pre_match
        else
          super(pattern, string, params, post_match:, pre_match:)
        end
      end
    end
  end
end
