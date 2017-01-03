# frozen_string_literal: true
require 'mustermann/visualizer/renderer/generic'

module Mustermann
  module Visualizer
    # @!visibility private
    module Renderer
      # Generates a s-expression like string.
      # @!visibility private
      class Sexp < Generic
        # @!visibility private
        def render
          @inspect = false
          super.gsub(/ ?\)( \))*/) { |s| s.gsub(' ', '') }.strip
        end


        # @!visibility private
        def pre(type)
          "(#{type} " if type != :pattern
        end

        # @!visibility private
        def escape_string(input)
          inspect = input.inspect
          input   = inspect if inspect != "\"#{input}\""
          input   = inspect if input =~ /[\s\"\'\(\)]/
          input + " "
        end

        # @!visibility private
        def post(type)
          ") " if type != :pattern
        end
      end
    end
  end
end
