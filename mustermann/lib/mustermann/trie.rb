# frozen_string_literal: true
require 'mustermann/trie/node'
require 'mustermann/trie/translator'

module Mustermann
  class Trie
    def initialize
      @root = Node.new
    end

    def add(pattern, value)
      pattern = pattern.to_pattern if pattern.respond_to?(:to_pattern)
      raise ArgumentError, "pattern must be AST-based" unless pattern.respond_to?(:to_ast) and pattern.respond_to?(:to_ast)
      node  = Translator.new(pattern.compiler, **pattern.options).translate(pattern.to_ast, pattern: pattern, value: value)
      @root = @root.merge(node)
      self
    end

    def match(string)
      @root.match(string, false)
    end

    def peek_match(string)
      @root.match(string, true)
    end
  end
end
