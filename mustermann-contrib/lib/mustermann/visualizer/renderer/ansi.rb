# frozen_string_literal: true
module Mustermann
  module Visualizer
    # @!visibility private
    module Renderer
      # Generates ANSI colored strings.
      # @!visibility private
      class ANSI
        # @!visibility private
        def initialize(target, mode: Hansi.mode, **options)
          @target  = target
          @mode    = mode
          @options = options
        end

        # @!visibility private
        def render
          template = @target.to_hansi_template(**@options)
          Hansi.render(template, tags: true, theme: @target.theme, mode: @mode)
        end
      end
    end
  end
end
