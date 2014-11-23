require 'mustermann/regular'

module Mustermann
  module Visualizer
    # @!visibility private
    module Renderer
      # Logic shared by most renderers.
      class Generic
        # @!visibility private
        def initialize(target, inspect: false)
          @target  = target
          @inspect = inspect
        end

        # @!visibility private
        def render
          quote = @inspect ? "#{pre(:quote)}\"#{post(:quote)}" : ""
          pre(:pattern).to_s + preamble.to_s + quote + @target.render(self) + quote + post(:pattern).to_s
        end

        # @!visibility private
        def preamble
        end

        # @!visibility private
        def escape(value)
          value = value.to_s
          value = value.inspect[1..-2] if @inspect
          escape_string(value)
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
