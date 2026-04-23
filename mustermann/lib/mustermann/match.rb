# frozen_string_literal: true

module Mustermann
  # The return value of {Mustermann::Pattern#match}, {Mustermann::Pattern#peek_match}, {Mustermann::Set#match}, and similar methods.
  # Mimics large parts of the MatchData API, but also provides access to the pattern and params hash.
  class Match
    # @return [Mustermann::Pattern] the pattern that produced the match
    attr_reader :pattern

    # @return [String] the string that was matched
    attr_reader :string

    # @return [Hash] the params hash
    attr_reader :params

    # @return [Array] the captures array
    attr_reader :captures

    # @return [Hash] the named captures hash, usually identical to {#params}
    attr_reader :named_captures

    # @return [String] the post match string
    attr_reader :post_match

    # @return [String] the pre match string
    attr_reader :pre_match

    # @return [Regexp, nil] the regular expression that produced the match, if available
    attr_reader :regexp

    # @overload initialize(pattern, string, **options)
    #   @param pattern [Mustermann::Pattern] the pattern that produced the match
    #   @param string [String] the string that was matched
    #
    # @overload initialize(match, **options)
    #   @param match [Mustermann::Match] the match to copy pattern and string from
    #
    # @overload initialize(pattern, match, **options)
    #   @param match [Mustermann::Match, MatchData] the match to copy string from
    #
    # @option options [Array]  :captures the captures array
    # @option options [Hash]   :named_captures the named captures hash
    # @option options [String] :matched the matched substring (defaults to string for full matches)
    # @option options [Hash]   :params the params hash
    # @option options [Regexp] :regexp the regular expression that produced the match
    # @option options [String] :post_match the post match string
    # @option options [String] :pre_match the pre match string
    def initialize(pattern_or_match, string_or_match = nil, matched: nil, params: nil, post_match: nil, pre_match: nil, captures: nil, named_captures: nil, regexp: nil)
      case pattern_or_match
      when Mustermann::Match, MatchData then match = pattern_or_match
      when Mustermann::Pattern          then pattern = pattern_or_match
      else raise ArgumentError, "first argument must be a Mustermann::Pattern or a MatchData, not #{pattern_or_match.class}"
      end

      case string_or_match
      when Mustermann::Match, MatchData then match ||= string_or_match
      when String                       then string = string_or_match
      when nil # ignore
      else raise ArgumentError, "second argument must be a String or a MatchData, not #{string_or_match.class}"
      end

      @pattern        = pattern        || match&.pattern
      @string         = string         || match&.string         || ''
      @params         = params         || match&.params         || {}
      @post_match     = post_match     || match&.post_match     || ''
      @pre_match      = pre_match      || match&.pre_match      || ''
      @captures       = captures       || match&.captures       || @params.values
      @named_captures = named_captures || match&.named_captures || @params
      @matched        = matched        || match&.to_s           || @string

      unless @regexp = regexp
        @regexp = match.regexp if match.respond_to?(:regexp)
        @regexp ||= pattern.respond_to?(:regexp) ? pattern.regexp : nil
      end
    end

    # @return [Array<String>] the names of the named captures
    def names = named_captures.keys

    # @overload [](key)
    #   Access named captures by key.
    #   @param key [String, Symbol] the key to access
    #   @return the value of the named capture, or nil if not found
    #
    # @overload [](index)
    #   Access captures by index.
    #   @param index [Integer] the index to access
    #   @return the value of the capture, or nil if not found
    #
    # @overload [](start, length)
    #   Access multiple captures by index and length.
    #   @param start [Integer] the starting index to access
    #   @param length [Integer] the number of captures to access
    #   @return [Array] the values of the captures
    #
    # @overload [](range)
    #   Access multiple captures by range.
    #   @param range [Range] the range of indices to access
    #   @return [Array] the values of the captures
    def [](key, length = nil)
      case key
      when String  then named_captures[key]
      when Symbol  then named_captures[key.to_s]
      when Integer then length ? captures[key, length] : captures[key]
      when Range   then captures[key]
      else raise ArgumentError, "key must be a String, Symbol, Integer, or Range, not #{key.class}"
      end
    end

    # Deconstructs the match into a hash of the given keys. Useful for pattern matching.
    # @param keys [Array] the keys to deconstruct
    # @return [Hash] a hash of the given keys and their corresponding values
    # @see https://docs.ruby-lang.org/en/4.0/syntax/pattern_matching_rdoc.html
    def deconstruct_keys(keys) = keys.to_h { |key| [key, self[key]] }

    # @see Object#hash
    def hash = pattern.hash ^ string.hash ^ params.hash

    # @see Object#eql?
    def eql?(other)
      return false unless other.is_a? self.class
      pattern == other.pattern && string == other.string && params == other.params
    end

    # Returns the values of the given keys as an array.
    # @params keys [Array<Symbol, String>] the keys to access
    # @return [Array] the values of the given keys
    def values_at(*keys) = keys.map { |key| self[key] }

    # @return [String] the matched substring (like MatchData#to_s)
    def to_s = @matched

    alias == eql?
    alias to_h params

    # @!visibility private
    def inspect
      params_str = params.map { |k, v| " #{k}:#{v.inspect}" }.join
      "#<#{self.class.name}: #{@matched.inspect}#{params_str}>"
    end

    # @!visibility private
    def pretty_print(q)
      q.group(1, "#<#{self.class.name}:", ">") do
        q.breakable
        q.pp @matched
        params.each do |key, value|
          q.breakable
          q.text("#{key}:")
          q.pp value
        end
      end
    end
  end
end
