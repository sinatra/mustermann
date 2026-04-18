# frozen_string_literal: true
require 'mustermann'
require 'mustermann/expander'
require 'mustermann/set/cache'
require 'mustermann/set/linear'
require 'mustermann/set/trie'

module Mustermann
  # @note Adding patterns via {#add}, {#update}, or {#[]=} is not thread-safe, but matching and expanding is.
  class Set
    attr_reader :options

    # @param use_trie [Boolean, Integer] whether to use a trie for matching, or the threshold for using a trie
    # @param additional_values [Symbol] behavior when encountering additional values on expansion, see {Mustermann::Expander#additional_values}
    # @param options [Hash] options used when creating patterns, see {Mustermann.new}
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

    alias []= add

    def [](pattern_or_string)
      case pattern_or_string
      when String  then match(pattern_or_string)&.value
      when Pattern then values_for_pattern(pattern_or_string)&.first
      else raise ArgumentError, "unsupported pattern type #{pattern_or_string.class}"
      end
    end

    def match(string) = @matcher&.match(string)

    def peek_match(string) = @matcher&.match(string, peek: true)

    def match_all(string) = @matcher&.match(string, all: true)

    def merge(mapping) = dup.update(mapping)

    def update(mapping)
      case mapping
      when Set             then @mappings.merge!(mapping.mapping) { |_, old, new| old + new }
      when Hash            then mapping.each { |k, v| add(k, v) }
      when String, Pattern then add(mapping)
      when Array           then mapping.each { |item| update(item) }
      else raise ArgumentError, "unsupported mapping type #{mapping.class}"
      end
      self
    end

    alias merge! update

    # A list of all the patterns in the set
    # @return [Array<Pattern>] the patterns in the set
    def patterns = @mapping.keys
    
    def expander(value = self)
      @expander[value] ||= begin
        patterns = value == self ? @mapping.keys : @reverse_mapping[value] || []
        Mustermann::Expander.new(patterns, additional_values: @additional_values, **options)
      end
    end

    def expand(value = self, behavior = nil, values = nil)
      if Expander::ADDITIONAL_VALUES.include? value
        if behavior.is_a? Hash
          values   = values ? values.merge(behavior) : behavior
          behavior = nil
        elsif behavior and behavior != value
          raise ArgumentError, "behavior specified multiple times" if behavior
        end
        value    = self
        behavior = value
      elsif value.is_a? Hash and behavior.nil? and values.nil?
        value  = self unless @reverse_mapping.key? value
        values = value
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
