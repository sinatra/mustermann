# -*- encoding: utf-8 -*-
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
      translate(:node) { "#{t.type(node)} #{t(payload)}" }
      translate(:with_look_ahead) { "#{t.type(node)} #{t(head)} #{t(payload)}" }

      # Turns a class name into a node identifier.
      #
      # @!visibility private
      def type(node)
        node.class.name[/[^:]+$/].split(/(?<=.)(?=[A-Z])/).map(&:downcase).join(?_)
      end
    end
  end
end