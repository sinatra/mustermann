# frozen_string_literal: true
require 'hansi'

module Mustermann
  module Visualizer
    # Represents a (sub)tree and at the same time a node in the tree.
    class Tree
      # @!visibility private
      attr_reader :line, :children, :prefix_color, :before, :after

      # @!visibility private
      def initialize(line, *children, prefix_color: :default, before: "", after: "")
        @line         = line
        @children     = children
        @prefix_color = prefix_color
        @before       = before
        @after        = after
      end

      # used for positioning {#after}
      # @!visibility private
      def line_widths(offset = 0)
        child_widths = children.flat_map { |c| c.line_widths(offset + 2)  }
        width        = length(line + before) + offset
        [width, *child_widths]
      end

      # Renders the tree.
      # @return [String] rendered version of the tree
      def to_s
        render("", "", line_widths.max)
      end

      # Renders tree, including nesting.
      # @!visibility private
      def render(first_prefix, prefix, width)
        output = before + Hansi.render(prefix_color, first_prefix) + line
        output = ljust(output, width) + "  " + after + "\n"
        children[0..-2].each { |child| output += child.render(prefix + "├ ", prefix + "│ ", width) }
        output += children.last.render(prefix + "└ ", prefix + "  ", width) if children.last
        output
      end

      # @!visibility private
      def length(string)
        deansi(string).length
      end

      # @!visibility private
      def deansi(string)
        string.gsub(/\e\[[^m]+m/, '')
      end

      # @!visibility private
      def ljust(string, width)
        missing = width - length(string)
        append  = missing > 0 ? " " * missing : ""
        string + append
      end

      private :ljust, :deansi, :length
    end
  end
end
