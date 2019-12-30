# frozen_string_literal: true
require 'mustermann/visualizer/renderer/generic'

module Mustermann
  module Visualizer
    # @!visibility private
    module Renderer
      # Generates Hansi template string.
      # @see Mustermann::Visualizer::Renderer::ANSI
      # @!visibility private
      class HansiTemplate < Generic
        # @!visibility private
        def initialize(*, **)
          @hansi = Hansi::StringRenderer.new(tags: true)
          super
        end

        # @!visibility private
        def escape_string(string)
          @hansi.escape(string)
        end

        # @!visibility private
        def pre(type)
          "<#{type}>"
        end

        # @!visibility private
        def post(type)
          "</#{type}>"
        end
      end
    end
  end
end
