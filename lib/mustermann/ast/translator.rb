require 'mustermann/ast/node'
require 'mustermann/error'
require 'delegate'

module Mustermann
  module AST
    class Translator
      class NodeTranslator < DelegateClass(Node)
        def self.register(*types)
          types.each do |type|
            type = Node.constant_name(type) if type.is_a? Symbol
            translator.dispatch_table[type.to_s] = self
          end
        end

        def initialize(node, translator)
          @translator = translator
          super(node)
        end

        attr_reader :translator

        def t(*args, &block)
          return translator unless args.any?
          translator.translate(*args, &block)
        end

        alias_method :node, :__getobj__
      end

      def self.dispatch_table
        @dispatch_table ||= {}
      end

      def self.inherited(subclass)
        node_translator = Class.new(NodeTranslator)
        node_translator.define_singleton_method(:translator) { subclass }
        subclass.const_set(:NodeTranslator, node_translator)
        super
      end

      def self.raises(error)
        define_method(:error_class) { error }
      end

      def self.translate(*types, &block)
        Class.new(const_get(:NodeTranslator)) do
          register(*types)
          define_method(:translate, &block)
        end
      end

      raises Mustermann::Error

      def decorator_for(node)
        factory = node.class.ancestors.inject(nil) { |d,a| d || self.class.dispatch_table[a.name] }
        raise error_class, "#{self.class}: Cannot translate #{node.class}" unless factory
        factory.new(node, self)
      end

      def translate(node, *args, &block)
        result = decorator_for(node).translate(*args, &block)
        result = result.node while result.is_a? NodeTranslator
        result
      end

      def uri_parser
        @uri_parser ||= URI::Parser.new
      end

      # @return [String] escaped character
      # @!visibility private
      def escape(char, parser: uri_parser, escape: parser.regexp[:UNSAFE], also_escape: nil)
        escape = Regexp.union(also_escape, escape) if also_escape
        char =~ escape ? parser.escape(char, Regexp.union(*escape)) : char
      end
    end
  end
end