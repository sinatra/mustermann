# frozen_string_literal: true
module Mustermann
  module Visualizer
    # @!visibility private
    module Renderer
      # Logic shared by most renderers.
      class Generic
        # @!visibility private
        def initialize(target, inspect: nil, add_qoutes: true)
          @target     = target
          @inspect    = inspect
          @add_qoutes = !target.pattern.is_a?(Mustermann::Composite)
        end

        # @!visibility private
        def render
          quote =  "#{pre(:quote)}#{escape_string(?")}#{post(:quote)}" if @inspect and @add_qoutes
          pre(:pattern).to_s + preamble.to_s + quote.to_s + @target.render(self) + quote.to_s + post(:pattern).to_s
        end

        # @!visibility private
        def preamble
        end

        # @!visibility private
        def escape(value, inspect_value = value.to_s.inspect[1..-2])
          escape_string(@inspect ? inspect_value : value.to_s)
        end

        # @!visibility private
        def escape_string(string)
          string
        end

        # @!visibility private
        def pre(type)
          ""
        end

        # @!visibility private
        def post(type)
          ""
        end
      end
    end
  end
end
