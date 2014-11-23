require 'mustermann/ast/translator'

module Mustermann
  module AST
    # Turns an AST into a human readable string.
    # @!visibility private
    class TreeRenderer < Translator
      # @example
      #   Mustermann::AST::TreeRenderer.render Mustermann::Sinatra::Parser.parse('/foo')
      #
      # @!visibility private
      def self.render(ast)
        new.translate(ast)
      end

      translate(Object) { inspect }
      translate(Array) { map { |e| "\n" << t(e) }.join.gsub("\n", "\n  ") }
      translate(:node) { "#{node.type} #{t(payload)}" }
      translate(:with_look_ahead) { "#{node.type} #{t(head)} #{t(payload)}" }
    end
  end
end