# frozen_string_literal: true
require 'mustermann'
require 'mustermann/pattern_cache'
require 'delegate'

module Mustermann
  # Class inspired by Ruby's StringScanner to scan an input string using multiple patterns.
  #
  # @example
  #   require 'mustermann/string_scanner'
  #   scanner = Mustermann::StringScanner.new("here is our example string")
  #
  #   scanner.scan("here") # => "here"
  #   scanner.getch        # => " "
  #
  #   if scanner.scan(":verb our")
  #     scanner.scan(:noun, capture: :word)
  #     scanner[:verb]  # => "is"
  #     scanner[:nound] # => "example"
  #   end
  #
  #   scanner.rest # => "string"
  #
  # @note
  #   This structure is not thread-safe, you should not scan on the same StringScanner instance concurrently.
  #   Even if it was thread-safe, scanning concurrently would probably lead to unwanted behaviour.
  class StringScanner
    # Exception raised if scan/unscan operation cannot be performed.
    ScanError     = Class.new(::ScanError)
    PATTERN_CACHE = PatternCache.new
    private_constant :PATTERN_CACHE

    # Patterns created by {#scan} will be globally cached, since we assume that there is a finite number
    # of different patterns used and that they are more likely to be reused than not.
    # This method allows clearing the cache.
    #
    # @see Mustermann::PatternCache
    def self.clear_cache
      PATTERN_CACHE.clear
    end

    # @return [Integer] number of cached patterns
    # @see clear_cache
    # @api private
    def self.cache_size
      PATTERN_CACHE.size
    end

    # Encapsulates return values for {StringScanner#scan}, {StringScanner#check}, and friends.
    # Behaves like a String (the substring which matched the pattern), but also exposes its position
    # in the main string and any params parsed from it.
    class ScanResult < DelegateClass(String)
      # The scanner this result came from.
      # @example
      #   require 'mustermann/string_scanner'
      #   scanner = Mustermann::StringScanner.new('foo/bar')
      #   scanner.scan(:name).scanner == scanner # => true
      attr_reader :scanner

      # @example
      #   require 'mustermann/string_scanner'
      #   scanner = Mustermann::StringScanner.new('foo/bar')
      #   scanner.scan(:name).position # => 0
      #   scanner.getch.position       # => 3
      #   scanner.scan(:name).position # => 4
      #
      # @return [Integer] position the substring starts at
      attr_reader :position
      alias_method :pos, :position

      # @example
      #   require 'mustermann/string_scanner'
      #   scanner = Mustermann::StringScanner.new('foo/bar')
      #   scanner.scan(:name).length # => 3
      #   scanner.getch.length       # => 1
      #   scanner.scan(:name).length # => 3
      #
      # @return [Integer] length of the substring
      attr_reader :length

      # Params parsed from the substring.
      # Will not include params from previous scan results.
      #
      # @example
      #   require 'mustermann/string_scanner'
      #   scanner = Mustermann::StringScanner.new('foo/bar')
      #   scanner.scan(:name).params # => { "name" => "foo" }
      #   scanner.getch.params       # => {}
      #   scanner.scan(:name).params # => { "name" => "bar" }
      #
      # @see Mustermann::StringScanner#params
      # @see Mustermann::StringScanner#[]
      #
      # @return [Hash] params parsed from the substring
      attr_reader :params

      # @api private
      def initialize(scanner, position, length, params = {})
        @scanner, @position, @length, @params = scanner, position, length, params
      end

      # @api private
      # @!visibility private
      def __getobj__
        @__getobj__ ||= scanner.to_s[position, length]
      end
    end

    # @return [Hash] default pattern options used for {#scan} and similar methods
    # @see #initialize
    attr_reader :pattern_options

    # Params from all previous matches from {#scan} and {#scan_until},
    # but not from {#check} and {#check_until}. Changes can be reverted
    # with {#unscan} and it can be completely cleared via {#reset}.
    #
    # @return [Hash] current params
    attr_reader :params

    # @return [Integer] current scan position on the input string
    attr_accessor :position
    alias_method :pos, :position
    alias_method :pos=, :position=

    # @example with different default type
    #   require 'mustermann/string_scanner'
    #   scanner = Mustermann::StringScanner.new("foo/bar/baz", type: :shell)
    #   scanner.scan('*')     # => "foo"
    #   scanner.scan('**/*')  # => "/bar/baz"
    #
    # @param [String] string the string to scan
    # @param [Hash] pattern_options default options used for {#scan}
    def initialize(string = "", **pattern_options)
      @pattern_options = pattern_options
      @string          = String(string).dup
      reset
    end

    # Resets the {#position} to the start and clears all {#params}.
    # @return [Mustermann::StringScanner] the scanner itself
    def reset
      @position = 0
      @params   = {}
      @history  = []
      self
    end

    # Moves the position to the end of the input string.
    # @return [Mustermann::StringScanner] the scanner itself
    def terminate
      track_result ScanResult.new(self, @position, size - @position)
      self
    end

    # Checks if the given pattern matches any substring starting at the current position.
    #
    # If it does, it will advance the current {#position} to the end of the substring and merges any params parsed
    # from the substring into {#params}.
    #
    # @param (see Mustermann.new)
    # @return [Mustermann::StringScanner::ScanResult, nil] the matched substring, nil if it didn't match
    def scan(pattern, **options)
      track_result check(pattern, **options)
    end

    # Checks if the given pattern matches any substring starting at any position after the current position.
    #
    # If it does, it will advance the current {#position} to the end of the substring and merges any params parsed
    # from the substring into {#params}.
    #
    # @param (see Mustermann.new)
    # @return [Mustermann::StringScanner::ScanResult, nil] the matched substring, nil if it didn't match
    def scan_until(pattern, **options)
      result, prefix = check_until_with_prefix(pattern, **options)
      track_result(prefix, result)
    end

    # Reverts the last operation that advanced the position.
    #
    # Operations advancing the position: {#terminate}, {#scan}, {#scan_until}, {#getch}.
    # @return [Mustermann::StringScanner] the scanner itself
    def unscan
      raise ScanError, 'unscan failed: previous match record not exist' if @history.empty?
      previous = @history[0..-2]
      reset
      previous.each { |r| track_result(*r) }
      self
    end

    # Checks if the given pattern matches any substring starting at the current position.
    #
    # Does not affect {#position} or {#params}.
    #
    # @param (see Mustermann.new)
    # @return [Mustermann::StringScanner::ScanResult, nil] the matched substring, nil if it didn't match
    def check(pattern, **options)
      params, length = create_pattern(pattern, **options).peek_params(rest)
      ScanResult.new(self, @position, length, params) if params
    end

    # Checks if the given pattern matches any substring starting at any position after the current position.
    #
    # Does not affect {#position} or {#params}.
    #
    # @param (see Mustermann.new)
    # @return [Mustermann::StringScanner::ScanResult, nil] the matched substring, nil if it didn't match
    def check_until(pattern, **options)
      check_until_with_prefix(pattern, **options).first
    end

    def check_until_with_prefix(pattern, **options)
      start      = @position
      @position += 1 until eos? or result = check(pattern, **options)
      prefix     = ScanResult.new(self, start, @position - start) if result
      [result, prefix]
    ensure
      @position  = start
    end

    # Reads a single character and advances the {#position} by one.
    # @return [Mustermann::StringScanner::ScanResult, nil] the character, nil if at end of string
    def getch
      track_result ScanResult.new(self, @position, 1) unless eos?
    end

    # Appends the given string to the string being scanned
    #
    # @example
    #   require 'mustermann/string_scanner'
    #   scanner = Mustermann::StringScanner.new
    #   scanner << "foo"
    #   scanner.scan(/.+/) # => "foo"
    #
    # @param [String] string will be appended
    # @return [Mustermann::StringScanner] the scanner itself
    def <<(string)
      @string << string
      self
    end

    # @return [true, false] whether or not the end of the string has been reached
    def eos?
      @position >= @string.size
    end

    # @return [true, false] whether or not the current position is at the start of a line
    def beginning_of_line?
      @position == 0 or @string[@position - 1] == "\n"
    end

    # @return [String] outstanding string not yet matched, empty string at end of input string
    def rest
      @string[@position..-1] || ""
    end

    # @return [Integer] number of character remaining to be scanned
    def rest_size
      @position > size ? 0 : size - @position
    end

    # Allows to peek at a number of still unscanned characters without advacing the {#position}.
    #
    # @param [Integer] length how many characters to look at
    # @return [String] the substring
    def peek(length = 1)
      @string[@position, length]
    end

    # Shorthand for accessing {#params}. Accepts symbols as keys.
    def [](key)
      params[key.to_s]
    end

    # (see #params)
    def to_h
      params.dup
    end

    # @return [String] the input string
    # @see #initialize
    # @see #<<
    def to_s
      @string.dup
    end

    # @return [Integer] size of the input string
    def size
      @string.size
    end

    # @!visibility private
    def inspect
      "#<%p %d/%d @ %p>" % [ self.class, @position, @string.size, @string ]
    end

    # @!visibility private
    def create_pattern(pattern, **options)
      PATTERN_CACHE.create_pattern(pattern, **options, **pattern_options)
    end

    # @!visibility private
    def track_result(*results)
      results.compact!
      @history << results if results.any?
      results.each do |result|
        @params.merge! result.params
        @position += result.length
      end
      results.last
    end

    private :create_pattern, :track_result, :check_until_with_prefix
  end
end
