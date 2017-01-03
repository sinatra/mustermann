# frozen_string_literal: true
require 'mustermann'
require 'mustermann/visualizer/highlight'
require 'mustermann/visualizer/tree_renderer'
require 'mustermann/visualizer/pattern_extension'

module Mustermann
  # Namespace for Mustermann visualization logic.
  module Visualizer
    extend self

    # @example creating a highlight object
    #   require 'mustermann/visualizer'
    #
    #   pattern   = Mustermann.new('/:name')
    #   highlight = Mustermann::Visualizer.highlight(pattern)
    #
    #   puts highlight.to_ansi
    #
    # @return [Mustermann::Visualizer::Highlight] highlight object for given pattern
    # @param (see Mustermann::Visualizer::Highlight#initialize)
    def highlight(pattern, **options)
      Highlight.new(pattern, **options)
    end

    # @example creating a tree object
    #   require 'mustermann/visualizer'
    #
    #   pattern = Mustermann.new('/:name')
    #   tree    = Mustermann::Visualizer.tree(pattern)
    #
    #   puts highlight.to_s
    #
    # @return [Mustermann::Visualizer::Tree] tree object for given pattern
    def tree(pattern, **options)
      TreeRenderer.render(pattern, **options)
    end
  end
end
