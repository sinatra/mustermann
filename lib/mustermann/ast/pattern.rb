require 'mustermann/ast/parser'
require 'mustermann/ast/compiler'
require 'mustermann/ast/transformer'
require 'mustermann/ast/validation'
require 'mustermann/ast/expander'
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
      instance_delegate %i[parser compiler transformer validation expander_class] => 'self.class'
      instance_delegate parse: :parser, transform: :transformer, validate: :validation

      # @api private
      # @return [#expand] expander object for pattern
      # @!visibility private
      attr_accessor :expander

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

      # @api private
      # @return [#new] expander factory for pattern
      # @!visibility private
      def self.expander_class
        Expander
      end

      # @!visibility private
      def compile(string, **options)
        self.expander      = expander_class.new
        options[:except] &&= parse options[:except]
        ast                = validate(transform(parse(string)))
        expander.add(ast)
        compiler.compile(ast, **options)
      rescue CompileError => error
        error.message << ": %p" % string
        raise error
      end

      # All AST-based pattern implementations support expanding.
      #
      # @example (see Mustermann::Pattern#expand)
      # @param (see Mustermann::Pattern#expand)
      # @return (see Mustermann::Pattern#expand)
      # @raise (see Mustermann::Pattern#expand)
      # @see Mustermann::Pattern#expand
      def expand(**values)
        expander.expand(**values)
      end

      private :compile
    end
  end
end