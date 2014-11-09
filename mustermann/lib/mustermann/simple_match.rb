module Mustermann
  # Fakes MatchData for patterns that do not support capturing.
  # @see http://ruby-doc.org/core-2.0/MatchData.html MatchData
  class SimpleMatch
    # @api private
    def initialize(string)
      @string = string.dup
    end

    # @return [String] the string that was matched against
    def to_s
      @string.dup
    end

    # @return [Array<String>] empty array for imitating MatchData interface
    def names
      []
    end

    # @return [Array<String>] empty array for imitating MatchData interface
    def captures
      []
    end

    # @return [nil] imitates MatchData interface
    def [](*args)
      captures[*args]
    end

    # @return [String] string representation
    def inspect
      "#<%p %p>" % [self.class, @string]
    end
  end
end
