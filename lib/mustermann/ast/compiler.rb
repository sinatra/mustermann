require 'mustermann/ast'

module Mustermann
  # @see Mustermann::AST::Pattern
  module AST
    # Object for turning a {AST::Node} into a {Regexp}
    # @!visibility private
    class Compiler
      # Turns parse tree into regular expression.
      #
      # @param [Mustermann::AST::Node] ast the parse tree
      # @param [Hash] **options compile options
      # @return [Regexp] compiled expression
      # @!visibility private
      def self.compile(ast, **options)
        new(**options).compile(ast)
      end

      # @param [Hash] **options compile options
      # @!visibility private
      def initialize(except: nil, **options)
        @options         = options
        options[:except] = compile(except, no_captures: true, **options) if except
      end

      # Turns parse tree into regular expression.
      #
      # @param [Mustermann::AST::Node] ast the parse tree
      # @param [Hash] **options compile options
      # @return [Regexp] compiled expression
      # @!visibility private
      def compile(ast, **options)
        ast.compile(**options, **@options)
      end
    end

    private_constant :Compiler
  end
end
