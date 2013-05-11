require 'mustermann/ast/translator'

module Mustermann
  module AST
    class Validation < Translator
      def self.validate(ast)
        new.translate(ast)
        ast
      end

      translate(Object, :splat) {}
      translate(:node) { t(payload) }
      translate(Array) { each { |p| t(p)} }

      translate(:capture, :variable, :named_splat) do
        raise CompileError, "capture name can't be empty" if name.nil? or name.empty?
        raise CompileError, "capture name must start with underscore or lower case letter" unless name =~ /^[a-z_]/
        raise CompileError, "capture name can't be #{name}" if name == "splat" or name == "captures"
        raise CompileError, "can't use the same capture name twice" if t.names.include? name
        t.names << name
      end

      def names
        @names ||= []
      end
    end
  end
end
