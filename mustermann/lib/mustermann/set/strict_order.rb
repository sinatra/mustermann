# frozen_string_literal: true

module Mustermann
  class Set
    class StrictOrder
      def initialize(matcher)
        @matcher = matcher
        @order   = {}
        @count   = 0
      end

      def add(...)  = @matcher.add(...)
      def optimize! = @matcher.optimize!
      
      def match(string, all: false, peek: false)
        possible = @matcher.match(string, all: true, peek: peek)
        possible.sort_by! { |m| @order.dig(m.pattern, m.value) }
        all ? possible : possible.first
      end

      def track(pattern, value)
        @order[pattern] ||= {}
        @order[pattern][value] = @count += 1
      end
    end

    private_constant :StrictOrder
  end
end
