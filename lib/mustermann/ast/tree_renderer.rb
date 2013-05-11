require 'mustermann/ast/translator'

module Mustermann
  module AST
    class TreeRenderer < Translator
      def self.render(ast)
        new.translate(ast)
      end

      translate(Object) { inspect }
      translate(Array) { map { |e| "\n" << t(e) }.join.gsub("\n", "\n  ") }
      translate(:node) { "#{t.type(node)} #{t(payload)}" }
      translate(:with_look_ahead) { "#{t.type(node)} #{t(head)} #{t(payload)}" }

      def type(node)
        node.class.name[/[^:]+$/].split(/(?<=.)(?=[A-Z])/).map(&:downcase).join(?_)
      end
    end
  end
end