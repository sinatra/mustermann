# frozen_string_literal: true

module Mustermann
  class Match
    attr_reader :pattern, :string, :params, :post_match, :pre_match

    def initialize(pattern, string, params = {}, post_match: '', pre_match: '')
      @pattern    = pattern
      @string     = string.freeze
      @params     = params.freeze
      @post_match = post_match.freeze
      @pre_match  = pre_match.freeze
    end

    def [](key)
      case key
      when String  then params[key]
      when Symbol  then params[key.to_s]
      else raise ArgumentError, "key must be a String or Symbol, not #{key.class}"
      end
    end
    
    def deconstruct_keys(keys) = keys.to_h { |key| [key, self[key]] }

    def hash = pattern.hash ^ string.hash ^ values.hash ^ params.hash
    
    def eql?(other)
      return false unless other.is_a? self.class
      pattern == other.pattern && string == other.string && params == other.params && value == other.value
    end

    def values_at(*keys) = keys.map { |key| self[key] }

    alias == eql?
    alias to_s string
    alias to_h params
    alias captures params

    private

    def evaluate(value) = value.is_a?(Proc) ? value.call : value
  end
end
