# frozen_string_literal: true
require 'mustermann/match'
require 'delegate'

module Mustermann
  class Set
    class Match < DelegateClass(Mustermann::Match)
      attr_reader :value

      def initialize(*args, value: nil, match: nil, **options)
        @value = value
        super(match || Mustermann::Match.new(*args, **options))
      end
    end
  end
end
