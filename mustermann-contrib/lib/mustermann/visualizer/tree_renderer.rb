# frozen_string_literal: true
require 'mustermann/visualizer/tree'
require 'mustermann/ast/translator'
require 'hansi'

module Mustermann
  module Visualizer
    # Turns an AST into a Tree
    # @!visibility private
    class TreeRenderer < AST::Translator
      TEMPLATE     = '"<base01>%s</base01><underline><green>%s</green></underline><base01>%s</base01>"  '
      THEME        = Hansi::Theme[:solarized]
      PREFIX_COLOR = THEME[:violet]
      FakeNode     = Struct.new(:type, :start, :stop, :length)
      private_constant(:TEMPLATE, :THEME, :PREFIX_COLOR, :FakeNode)

      # Takes a pattern (or pattern string and option) and turns it into a tree.
      # Runs translation if pattern implements to_ast, otherwise returns single
      # node tree.
      #
      # @!visibility private
      def self.render(pattern, **options)
        pattern &&= Mustermann.new(pattern, **options)
        renderer  = new(pattern.to_s)
        if pattern.respond_to? :to_ast
          renderer.translate(pattern.to_ast)
        else
          length = renderer.string.length
          node   = FakeNode.new("pattern (not AST based)", 0, length, length)
          renderer.tree(node)
        end
      end

      # @!visibility private
      attr_reader :string

      # @!visibility private
      def initialize(string)
        @string = string
      end

      # access a substring of the pattern, in inspect mode
      # @!visibility private
      def sub(*args)
        string[*args].inspect[1..-2]
      end

      # creates a tree node
      # @!visibility private
      def tree(node, *children, **typed_children)
        children   += children_for(typed_children)
        children    = children.flatten.grep(Tree)
        infos       = sub(0, node.start), sub(node.start, node.length), sub(node.stop..-1)
        description = Hansi.render(THEME[:green], node.type.to_s.tr("_", " "))
        after      = Hansi.render(TEMPLATE, *infos, theme: THEME, tags: true)
        Tree.new(description, *children, after: after, prefix_color: PREFIX_COLOR)
      end

      # Take a hash with trees as values and turn the keys into trees, too.
      # Read again if that didn't make sense.
      # @!visibility private
      def children_for(list)
        list.map do |key, value|
          value = Array(value).flatten
          if value.any?
            after      = " " * string.inspect.length + "  "
            description = Hansi.render(THEME[:orange], key.to_s)
            Tree.new(description, *value, after: after, prefix_color: PREFIX_COLOR)
          end
        end
      end

      translate(:node) { t.tree(node, payload: t(payload)) }
      translate(:with_look_ahead) { t.tree(node, head: t(head), payload: t(payload)) }
      translate(Array) { map { |e| t(e) }}
      translate(Object) { }
    end
  end
end
