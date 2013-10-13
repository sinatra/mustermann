require 'mustermann/error'
require 'mustermann/simple_match'
require 'mustermann/equality_map'
require 'uri'

module Mustermann
  # Superclass for all pattern implementations.
  # @abstract
  class Pattern
    # List of supported options.
    #
    # @overload supported_options
    #   @return [Array<Symbol>] list of supported options
    # @overload supported_options(*list)
    #   Adds options to the list.
    #
    #   @api private
    #   @param [Symbol] *list adds options to the list of supported options
    #   @return [Array<Symbol>] list of supported options
    def self.supported_options(*list)
      @supported_options ||= []
      options = @supported_options.concat(list)
      options += superclass.supported_options if self < Pattern
      options
    end

    # @param [Symbol] option The option to check.
    # @return [Boolean] Whether or not option is supported.
    def self.supported?(option)
      supported_options.include? option
    end

    # @overload new(string, **options)
    # @param (see #initialize)
    # @raise (see #initialize)
    # @raise [ArgumentError] if some option is not supported
    # @return [Mustermann::Pattern] a new instance of Mustermann::Pattern
    # @see #initialize
    def self.new(string, ignore_unknown_options: false, **options)
      unless ignore_unknown_options
        unsupported = options.keys.detect { |key| not supported?(key) }
        raise ArgumentError, "unsupported option %p for %p" % [unsupported, self] if unsupported
      end

      @map ||= EqualityMap.new
      @map.fetch(string, options) { super(string, options) }
    end

    supported_options :uri_decode, :ignore_unknown_options

    # @overload initialize(string, **options)
    # @param [String] string the string representation of the pattern
    # @param [Hash] options options for fine-tuning the pattern behavior
    # @raise [Mustermann::Error] if the pattern can't be generated from the string
    # @see file:README.md#Types_and_Options "Types and Options" in the README
    # @see Mustermann.new
    def initialize(string, uri_decode: true, **options)
      @uri_decode = uri_decode
      @string     = string.to_s.dup
    end

    # @return [String] the string representation of the pattern
    def to_s
      @string.dup
    end

    # @param [String] string The string to match against
    # @return [MatchData, Mustermann::SimpleMatch, nil] MatchData or similar object if the pattern matches.
    # @see http://ruby-doc.org/core-2.0/Regexp.html#method-i-match Regexp#match
    # @see http://ruby-doc.org/core-2.0/MatchData.html MatchData
    # @see Mustermann::SimpleMatch
    def match(string)
      SimpleMatch.new(string) if self === string
    end

    # @param [String] string The string to match against
    # @return [Integer, nil] nil if pattern does not match the string, zero if it does.
    # @see http://ruby-doc.org/core-2.0/Regexp.html#method-i-3D-7E Regexp#=~
    def =~(string)
      0 if self === string
    end

    # @param [String] string The string to match against
    # @return [Boolean] Whether or not the pattern matches the given string
    # @note Needs to be overridden by subclass.
    # @see http://ruby-doc.org/core-2.0/Regexp.html#method-i-3D-3D-3D Regexp#===
    def ===(string)
      raise NotImplementedError, 'subclass responsibility'
    end

    # @return [Array<String>] capture names.
    # @see http://ruby-doc.org/core-2.0/Regexp.html#method-i-named_captures Regexp#named_captures
    def named_captures
      {}
    end

    # @return [Hash{String: Array<Integer>}] capture names mapped to capture index.
    # @see http://ruby-doc.org/core-2.0/Regexp.html#method-i-names Regexp#names
    def names
      []
    end

    # @param [String] string the string to match against
    # @return [Hash{String: String, Array<String>}, nil] Sinatra style params if pattern matches.
    def params(string = nil, captures: nil, offset: 0)
      return unless captures ||= match(string)
      params   = named_captures.map do |name, positions|
        values = positions.map { |pos| map_param(name, captures[pos + offset]) }.flatten
        values = values.first if values.size < 2 and not always_array? name
        [name, values]
      end

      Hash[params]
    end

    # @note This method is only implemented by certain subclasses.
    #
    # @example Expanding a pattern
    #   pattern = Mustermann.new('/:name(.:ext)?')
    #   pattern.expand(name: 'hello')             # => "/hello"
    #   pattern.expand(name: 'hello', ext: 'png') # => "/hello.png"
    #
    # @example Checking if a pattern supports expanding
    #   if pattern.respond_to? :expand
    #     pattern.expand(name: "foo")
    #   else
    #     warn "does not support expanding"
    #   end
    #
    # @param [Hash{Symbol: #to_s, Array<#to_s>}] values values to use for expansion
    # @return [String] expanded string
    # @raise [NotImplementedError] raised if expand is not supported.
    # @raise [Mustermann::ExpandError] raised if a value is missing or unknown
    # @see Mustermann::Expander
    def expand(**values)
      raise NotImplementedError, "expanding not supported by #{self.class}"
    end

    # @!visibility private
    # @return [Boolean]
    # @see Object#respond_to?
    def respond_to?(method, *args)
      method.to_s == 'expand' ? false : super
    end

    # @!visibility private
    def inspect
      "#<%p:%p>" % [self.class, @string]
    end

    # @!visibility private
    def map_param(key, value)
      unescape(value, true)
    end

    # @!visibility private
    def unescape(string, decode = @uri_decode)
      return string unless decode and string
      @uri ||= URI::Parser.new
      @uri.unescape(string)
    end

    # @!visibility private
    ALWAYS_ARRAY = %w[splat captures]

    # @!visibility private
    def always_array?(key)
      ALWAYS_ARRAY.include? key
    end

    private :unescape, :map_param
    private_constant :ALWAYS_ARRAY
  end
end
