require 'mustermann/ast'
require 'mustermann/regexp_based'

module Mustermann
  # @see Mustermann::AST::Pattern
  module AST
    # Superclass for pattern styles that parse an AST from the string pattern.
    # @abstract
    class Pattern < Mustermann::RegexpBased
      supported_options :capture, :except, :greedy, :space_matches_plus

      extend Forwardable, SingleForwardable
      single_delegate on: :parser, suffix: :parser
      instance_delegate parser: "self.class", compiler: "self.class", parse: :parser

      # @api private
      # @return [#parse] parser object for pattern
      def self.parser
        return Parser if self == AST::Pattern
        const_set :Parser, Class.new(superclass.parser) unless const_defined? :Parser, false
        const_get :Parser
      end

      # @api private
      # @return [#compile] compiler object for pattern
      def self.compiler
        Compiler
      end

      # @!visibility private
      def compile(string, **options)
        options[:except] &&= parse(options[:except], **options)
        @ast = parse(string, **options)
        compiler.compile(@ast, **options)
      end

      # All AST-based pattern implementations support expanding.
      #
      # @example (see Mustermann::Pattern#expand)
      # @param (see Mustermann::Pattern#expand)
      # @return (see Mustermann::Pattern#expand)
      # @raise (see Mustermann::Pattern#expand)
      # @see Mustermann::Pattern#expand
      def expand(**values)
        @ast.expand(**values)
      end

      private :compile
    end
  end
end