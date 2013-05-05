require 'mustermann/ast/node'

module Mustermann
  module AST
    class Node
      # AST node for template variables.
      # @!visibility private
      class Variable < Capture
        # @!visibility private
        attr_accessor :prefix, :explode

        # @!visibility private
        def compile(**options)
          return super(**options) if explode or not options[:parametric]
          parametric super(parametric: false, **options)
        end

        # @!visibility private
        def pattern(parametric: false, **options)
          register_param(parametric: parametric, **options)
          pattern = super(**options)
          pattern = parametric(pattern) if parametric
          pattern = "#{pattern}(?:#{Regexp.escape(options.fetch(:separator))}#{pattern})*" if explode
          pattern
        end

        # @!visibility private
        def parametric(string)
          "#{Regexp.escape(name)}(?:=#{string})?"
        end

        # @!visibility private
        def qualified(string, **options)
          prefix ? "#{string}{1,#{prefix}}" : super(string, **options)
        end

        # @!visibility private
        def default(allow_reserved: false, **options)
          allow_reserved ? '[\w\-\.~%\:/\?#\[\]@\!\$\&\'\(\)\*\+,;=]' : '[\w\-\.~%]'
        end

        # @!visibility private
        def register_param(parametric: false, split_params: nil, separator: nil, **options)
          return unless explode and split_params
          split_params[name] = { separator: separator, parametric: parametric }
        end
      end
    end
  end
end