# frozen_string_literal: true
module Mustermann
  module Visualizer
    # @!visibility private
    module Highlighter
      # Provides highlighting for patterns that don't have a highlighter.
      # @!visibility private
      module Dummy
        # @!visibility private
        def self.highlight(pattern, renderer)
          output = String.new
          output << renderer.pre(:root) << renderer.pre(:unknown)
          output << renderer.escape(pattern.to_s)
          output << renderer.post(:unknown) << renderer.post(:root)
        end
      end
    end
  end
end
