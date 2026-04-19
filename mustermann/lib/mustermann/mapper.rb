# frozen_string_literal: true
require 'mustermann'
require 'mustermann/expander'
require 'mustermann/set'

module Mustermann
  # A mapper allows mapping one string to another based on pattern parsing and expanding.
  #
  # @example
  #   require 'mustermann/mapper'
  #   mapper = Mustermann::Mapper.new("/:foo" => "/:foo.html")
  #   mapper['/example'] # => "/example.html"
  class Mapper
    # Creates a new mapper.
    #
    # @overload initialize(**options)
    #   @param options [Hash] options The options hash
    #   @yield block for generating mappings as a hash
    #   @yieldreturn [Hash] see {#update}
    #
    #   @example
    #     require 'mustermann/mapper'
    #     Mustermann::Mapper.new(type: :rails) {{
    #       "/:foo" => ["/:foo.html", "/:foo.:format"]
    #     }}
    #
    # @overload initialize(**options)
    #   @param  options [Hash] options The options hash
    #   @yield block for generating mappings as a hash
    #   @yieldparam mapper [Mustermann::Mapper] the mapper instance
    #
    #   @example
    #     require 'mustermann/mapper'
    #     Mustermann::Mapper.new(type: :rails) do |mapper|
    #       mapper["/:foo"] = ["/:foo.html", "/:foo.:format"]
    #     end
    #
    # @overload initialize(map = {}, **options)
    #   @param map [Hash] see {#update}
    #   @param [Hash] options The options hash
    #
    #   @example map before options
    #     require 'mustermann/mapper'
    #     Mustermann::Mapper.new({"/:foo" => "/:foo.html"}, type: :rails)
    def initialize(map = {}, additional_values: :ignore, **options, &block)
      @options           = options
      @additional_values = additional_values
      @set               = Set.new(use_trie: false, use_cache: false, **options)
      block.arity == 0 ? update(yield) : yield(self) if block
      update(map) if map
    end

    # Add multiple mappings.
    #
    # @param map [Hash{String, Pattern: String, Pattern, Arry<String, Pattern>, Expander}] the mapping
    def update(map)
      map.to_h.each_pair do |input, output|
        output = Expander.new(*output, additional_values: @additional_values, **@options) unless output.is_a? Expander
        @set.add(input, output)
      end
    end

    # @return [Hash{Patttern: Expander}] Hash version of the mapper.
    def to_h
      @set.patterns.each_with_object({}) do |pattern, h|
        h[pattern] = @set.values_for_pattern(pattern).first
      end
    end

    # Convert a string according to mappings. You can pass in additional params.
    #
    # @example mapping with and without additional parameters
    #   mapper = Mustermann::Mapper.new("/:example" => "(/:prefix)?/:example.html")
    #
    def convert(input, values = {})
      @set.patterns.inject(input) do |current, pattern|
        @set.values_for_pattern(pattern).inject(current) do |str, expander|
          params = pattern.params(str)
          params &&= Hash[values.merge(params).map { |k, v| [k.to_s, v] }]
          expander.expandable?(params) ? expander.expand(params) : str
        end
      end
    end

    # Add a single mapping.
    #
    # @param key [String, Pattern] format of the input string
    # @param value [String, Pattern, Arry<String, Pattern>, Expander] format of the output string
    def []=(key, value)
      update key => value
    end

    alias_method :[], :convert
  end
end
