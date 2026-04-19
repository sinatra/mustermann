# frozen_string_literal: true
require 'mustermann'
require 'mustermann/expander'
require 'mustermann/set/cache'
require 'mustermann/set/linear'
require 'mustermann/set/trie'

module Mustermann
  # A collection of patterns that can be matched against strings efficiently.
  #
  # Each pattern in the set may be associated with one or more arbitrary values,
  # such as handler objects or route actions. A single {#match} call returns a
  # {Set::Match} that provides both the captured parameters and the associated
  # value for the matched pattern. When the set contains many patterns, an
  # internal trie (prefix tree) is used to dispatch requests in sub-linear time.
  #
  # @example Building a routing table
  #   require 'mustermann/set'
  #
  #   set = Mustermann::Set.new
  #   set.add('/users/:id',  :users_show)
  #   set.add('/posts/:id',  :posts_show)
  #
  #   m = set.match('/users/42')
  #   m.value          # => :users_show
  #   m.params['id']   # => '42'
  #
  # @example Constructor shorthand with a hash
  #   set = Mustermann::Set.new('/users/:id' => :users_show, '/posts/:id' => :posts_show)
  #
  # @example Block syntax
  #   set = Mustermann::Set.new do |s|
  #     s.add('/users/:id', :users_show)
  #     s.add('/posts/:id', :posts_show)
  #   end
  #
  # @note Adding patterns via {#add}, {#update}, or {#[]=} is not thread-safe, but matching and expanding is.
  class Set
    # Pattern options forwarded to {Mustermann.new} when patterns are created from strings.
    # @return [Hash]
    attr_reader :options

    # Creates a new set, optionally pre-populated with patterns.
    #
    # Patterns can be supplied as a Hash (pattern → value), a plain String or
    # Pattern, an Array of any of these, or an existing {Set}. The same forms
    # are accepted by {#update} and {#add}.
    #
    # @example Empty set
    #   Mustermann::Set.new
    #
    # @example Pre-populated from a hash
    #   Mustermann::Set.new('/users/:id' => :users, '/posts/:id' => :posts)
    #
    # @example Imperative block
    #   Mustermann::Set.new do |s|
    #     s.add('/users/:id', :users)
    #   end
    #
    # @example Zero-argument block returning a mapping hash
    #   Mustermann::Set.new { { '/users/:id' => :users } }
    #
    # @param mapping [Array] initial patterns or mappings to add
    # @param additional_values [:raise, :ignore, :append] behavior when extra keys are passed to {#expand};
    #   defaults to +:raise+
    # @param options [Hash] pattern options forwarded to {Mustermann.new} (e.g. +type: :rails+)
    # @raise [ArgumentError] if +additional_values+ is not a recognized behavior symbol
    def initialize(*mapping, additional_values: :raise, use_trie: 50, use_cache: true, **options, &block)
      raise ArgumentError, "Illegal value %p for additional_values" % additional_values unless Expander::ADDITIONAL_VALUES.include? additional_values
      raise ArgumentError, "Illegal value %p for use_trie" % use_trie unless [true, false].include?(use_trie) or use_trie.is_a? Integer

      @use_trie          = use_trie
      @use_cache         = use_cache
      @matcher           = nil
      @mapping           = {}
      @reverse_mapping   = {}
      @options           = {}
      @expanders         = {}
      @additional_values = additional_values

      options.each do |key, value|
        if key.is_a? Symbol
          @options[key] = value
        else
          mapping << { key => value }
        end
      end

      update(mapping)

      block.arity == 0 ? update(yield) : yield(self) if block
    end

    # Adds a pattern to the set, optionally associated with one or more values.
    #
    # If the pattern is given as a String it will be compiled via {Mustermann.new}
    # using the set's own options. The pattern must be AST-based (Sinatra, Rails,
    # and similar types). Plain regexp patterns are not supported.
    #
    # Calling +add+ more than once for the same pattern appends additional values
    # without creating duplicates.
    #
    # @example
    #   set.add('/users/:id', :users)
    #   set.add('/users/:id', :admin)   # same pattern, second value
    #
    # @param pattern [String, Pattern] the pattern to add
    # @param values [Array] zero or more values to associate with the pattern
    # @return [self]
    # @raise [ArgumentError] if the pattern is not AST-based, or if a reserved symbol is used as a value
    def add(pattern, *values)
      pattern = Mustermann.new(pattern, **options)
      raise ArgumentError, "Non-AST patterns are not supported" unless pattern.respond_to? :to_ast

      if @mapping.key? pattern
        current = @mapping[pattern]
      else
        add_pattern(pattern)
        current = @mapping[pattern] = []
      end

      values = [nil] if values.empty?

      values.each do |value|
        raise ArgumentError, "%p may not be used as a value" % value if Expander::ADDITIONAL_VALUES.include? value
        raise ArgumentError, "the set itself may not be used as value" if value == self
        next if current.include? value
        current << value
        @reverse_mapping[value] ||= []
        @reverse_mapping[value] << pattern unless @reverse_mapping[value].include? pattern
        @expanders[value]&.add(pattern)
      end

      self
    end

    # Adds a pattern associated with a value using hash-assignment syntax.
    # @see #add
    alias []= add

    # Looks up a value by string or retrieves the first value for a known pattern object.
    #
    # When given a String, it is matched against the set and the associated value of the
    # first matching pattern is returned. When given a {Pattern}, the first value
    # registered for that exact pattern is returned without matching.
    #
    # @example String lookup
    #   set['/users/42']  # => :users_show (or nil)
    #
    # @example Pattern lookup
    #   pat = Mustermann.new('/users/:id')
    #   set[pat]          # => :users_show (or nil)
    #
    # @param pattern_or_string [String, Pattern]
    # @return [Object, nil] the associated value, or +nil+ if not found
    # @raise [ArgumentError] for unsupported argument types
    def [](pattern_or_string)
      case pattern_or_string
      when String  then match(pattern_or_string)&.value
      when Pattern then values_for_pattern(pattern_or_string)&.first
      else raise ArgumentError, "unsupported pattern type #{pattern_or_string.class}"
      end
    end

    # Matches the string against all patterns in the set and returns the first match.
    #
    # @param string [String] the string to match
    # @return [Set::Match, nil] the first match, or +nil+ if none of the patterns match
    def match(string) = @matcher&.match(string)

    # Matches the beginning of the string against all patterns and returns the
    # first prefix match. The unmatched remainder of the string is available via
    # {Set::Match#post_match}.
    #
    # @param string [String]
    # @return [Set::Match, nil] the first prefix match, or +nil+
    def peek_match(string) = @matcher&.match(string, peek: true)

    # Matches the string against all patterns and returns every match, one per
    # (pattern, value) pair, in insertion order.
    #
    # @param string [String]
    # @return [Array<Set::Match>] all matches, or an empty array if none
    def match_all(string) = @matcher&.match(string, all: true)

    # Matches the beginning of the string against all patterns and returns every
    # prefix match, one per (pattern, value) pair. The unmatched remainder is
    # available as {Set::Match#post_match} on each result.
    #
    # @param string [String]
    # @return [Array<Set::Match>] all prefix matches, or an empty array if none
    def peek_match_all(string) = @matcher&.match(string, all: true, peek: true)

    # Returns a new set that includes all patterns from the receiver plus those
    # from +mapping+. The receiver is not modified.
    #
    # @param mapping [Hash, String, Pattern, Array, Set] patterns to merge in
    # @return [Set] a new set
    def merge(mapping) = dup.update(mapping)

    # @!visibility private
    def initialize_copy(other)
      @mapping         = other.mapping.transform_values(&:dup)
      @reverse_mapping = @mapping.each_with_object({}) do |(pattern, values), h|
        values.each { |value| (h[value] ||= []) << pattern }
      end
      @expanders = {}
      @matcher   = nil
      @mapping.each_key { |pattern| add_pattern(pattern) }
    end

    # Adds all patterns from +mapping+ to the set in place and returns +self+.
    # Aliased as +merge!+.
    #
    # Accepts the same argument forms as {#initialize}: a Hash, a String, a
    # {Pattern}, an Array, or another {Set}.
    #
    # @param mapping [Hash, String, Pattern, Array, Set]
    # @return [self]
    # @raise [ArgumentError] for unsupported mapping types
    def update(mapping)
      case mapping
      when Set             then mapping.mapping.each { |pattern, values| add(pattern, *values) }
      when Hash            then mapping.each { |k, v| add(k, v) }
      when String, Pattern then add(mapping)
      when Array           then mapping.each { |item| update(item) }
      else raise ArgumentError, "unsupported mapping type #{mapping.class}"
      end
      self
    end

    alias merge! update

    # Returns all patterns that have been added to the set, in insertion order.
    # @return [Array<Pattern>]
    def patterns = @mapping.keys

    # Returns an {Expander} that can generate strings from parameter hashes.
    #
    # When called without arguments (or with the set itself as the value) the
    # expander covers all patterns in the set. Pass a specific value to get an
    # expander limited to the patterns associated with that value.
    #
    # @param value [Object] restricts the expander to patterns associated with
    #   this value; defaults to the set itself (all patterns)
    # @return [Mustermann::Expander]
    def expander(value = self)
      @expanders[value] ||= begin
        patterns = value == self ? @mapping.keys : @reverse_mapping[value] || []
        Mustermann::Expander.new(patterns, additional_values: @additional_values, **options)
      end
    end

    # Generates a string from a parameter hash using the patterns in the set.
    #
    # When called with just a parameter hash, the first pattern that can be fully
    # expanded with those keys is used. Pass a value as the first argument to
    # restrict expansion to the patterns associated with that value. You may also
    # pass an +additional_values+ behavior symbol (+:raise+, +:ignore+, or
    # +:append+) as the first argument to override the set's default behavior for
    # that call.
    #
    # @example Expand using any pattern
    #   set.expand(id: '5')
    #
    # @example Expand patterns for a specific value
    #   set.expand(:users, id: '5')
    #
    # @example Override additional_values behavior for one call
    #   set.expand(:ignore, id: '5', extra: 'ignored')
    #
    # @param value [Object, :raise, :ignore, :append] the value whose patterns
    #   should be used, or an additional_values behavior symbol; defaults to all
    #   patterns
    # @param behavior [:raise, :ignore, :append, nil] how to handle extra keys;
    #   defaults to the set's +additional_values+ setting
    # @param values [Hash, nil] the parameters to expand
    # @return [String]
    # @raise [Mustermann::ExpandError] if no pattern can be expanded with the given keys
    def expand(value = self, behavior = nil, values = nil)
      if Expander::ADDITIONAL_VALUES.include? value
        if behavior.is_a? Hash
          values   = values ? values.merge(behavior) : behavior
          behavior = nil
        elsif behavior and behavior != value
          raise ArgumentError, "behavior specified multiple times" if behavior
        end
        behavior = value
        value    = self
      elsif value.is_a? Hash and behavior.nil? and values.nil?
        values = value
        value  = self unless @reverse_mapping.key? values
      end
      expander(value).expand(behavior || @additional_values, values || {})
    end

    # @!visibility private
    def values_for_pattern(pattern) = @mapping[pattern] # :nodoc:

    protected

    attr_reader :mapping

    private

    def add_pattern(pattern)
      case @use_trie
      when true
        @matcher ||= Trie.new(self, @mapping.keys)
      when Integer
        if @mapping.size >= @use_trie
          @matcher = Trie.new(self, @mapping.keys)
          @use_trie = true
        end
      end

      @matcher ||= Linear.new(self, @mapping.keys)
      @matcher = Cache.new(@matcher) if @use_cache and not @matcher.is_a? Cache
      @matcher.add(pattern)

      @expanders[self]&.add(pattern)
    end
  end
end
