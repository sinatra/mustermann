# frozen_string_literal: true
require 'mustermann/match'

module Mustermann
  class Set

    # Subclass of {Mustermann::Match} that also includes the value associated with the pattern that produced the match.
    class Match < Mustermann::Match
      # @return the value associated with the pattern that produced the match, if any
      attr_reader :value

      # (see Mustermann::Match#initialize)
      # @option options [Object] :value the value associated with the pattern that produced the match, if any
      def initialize(*, value: nil, **)
        @value = value
        super(*, **)
      end

      # @see Mustermann::Match#eql?
      def eql?(other) = super && value == other.value
    end
  end
end
