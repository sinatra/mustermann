require 'mustermann/ast/parser'
require 'mustermann/ast/compiler'
require 'mustermann/ast/transformer'
require 'mustermann/ast/validation'
require 'mustermann/ast/template_generator'
require 'mustermann/ast/param_scanner'
require 'mustermann/regexp_based'
require 'mustermann/expander'
require 'tool/equality_map'

module Mustermann
  # @see Mustermann::AST::Pattern
  module AST
    # Superclass for pattern styles that parse an AST from the string pattern.
    # @abstract
    class Pattern < Mustermann::RegexpBased
      supported_options :capture, :except, :greedy, :space_matches_plus

      extend Forwardable, SingleForwardable
      single_delegate on: :parser, suffix: :parser
      instance_delegate %i[parser compiler transformer validation template_generator param_scanner] => 'self.class'
      instance_delegate parse: :parser, transform: :transformer, validate: :validation,
        generate_templates: :template_generator, scan_params: :param_scanner

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
      # @return [#generate_templates] generates URI templates for pattern
      # @!visibility private
      def self.template_generator
        TemplateGenerator
      end

      # @api private
      # @return [#scan_params] param scanner for pattern
      # @!visibility private
      def self.param_scanner
        ParamScanner
      end

      # @!visibility private
      def compile(**options)
        options[:except] &&= parse options[:except]
        compiler.compile(to_ast, **options)
      rescue CompileError => error
        error.message << ": %p" % @string
        raise error
      end

      # Internal AST representation of pattern.
      # @!visibility private
      def to_ast
        @ast_cache ||= Tool::EqualityMap.new
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
      def expand(behavior = nil, **values)
        @expander ||= Mustermann::Expander.new(self)
        @expander.expand(behavior, **values)
      end

      # All AST-based pattern implementations support generating templates.
      #
      # @example (see Mustermann::Pattern#to_templates)
      # @param (see Mustermann::Pattern#to_templates)
      # @return (see Mustermann::Pattern#to_templates)
      # @see Mustermann::Pattern#to_templates
      def to_templates
        @to_templates ||= generate_templates(to_ast)
      end

      # @!visibility private
      # @see Mustermann::Pattern#map_param
      def map_param(key, value)
        return super unless param_converters.include? key
        param_converters[key][super]
      end

      # @!visibility private
      def param_converters
        @param_converters ||= scan_params(to_ast)
      end

      private :compile, :parse, :transform, :validate, :generate_templates, :param_converters, :scan_params
    end
  end
end