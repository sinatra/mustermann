# -*- encoding: utf-8 -*-
require 'mustermann/ast/parser'
require 'mustermann/ast/compiler'
require 'mustermann/ast/transformer'
require 'mustermann/ast/validation'
require 'mustermann/regexp_based'
require 'mustermann/expander'
require 'mustermann/equality_map'

module Mustermann
  # @see Mustermann::AST::Pattern
  module AST
    # Superclass for pattern styles that parse an AST from the string pattern.
    # @abstract
    class Pattern < Mustermann::RegexpBased
      supported_options :capture, :except, :greedy, :space_matches_plus

      extend Forwardable, SingleForwardable
      single_delegate on: :parser, suffix: :parser
      instance_delegate %w[parser compiler transformer validation].map(&:to_sym) => 'self.class'
      instance_delegate parse: :parser, transform: :transformer, validate: :validation

      # @api private
      # @return [#parse] parser object for pattern
      # @!visibility private
      def self.parser
        return Parser if self == AST::Pattern
        const_set :Parser, Class.new(superclass.parser) unless const_defined? :Parser, false
        const_get :Parser
      end

      # @api private
      # @return [#compile] compiler object for pattern
      # @!visibility private
      def self.compiler
        Compiler
      end

      # @api private
      # @return [#transform] compiler object for pattern
      # @!visibility private
      def self.transformer
        Transformer
      end

      # @api private
      # @return [#validate] validation object for pattern
      # @!visibility private
      def self.validation
        Validation
      end

      # @!visibility private
      def compile(options = {})
        options[:except] &&= parse options[:except]
        compiler.compile(to_ast, options)
      rescue CompileError => error
        error.message << ": %p" % @string
        raise error
      end

      # Internal AST representation of pattern.
      # @!visibility private
      def to_ast
        @ast_cache ||= EqualityMap.new
        @ast_cache.fetch(@string) { validate(transform(parse(@string))) }
      end

      # All AST-based pattern implementations support expanding.
      #
      # @example (see Mustermann::Pattern#expand)
      # @param (see Mustermann::Pattern#expand)
      # @return (see Mustermann::Pattern#expand)
      # @raise (see Mustermann::Pattern#expand)
      # @see Mustermann::Pattern#expand
      # @see Mustermann::Expander
      def expand(values = {})
        @expander ||= Mustermann::Expander.new(self)
        @expander.expand(values)
      end

      private :compile
    end
  end
end
