# frozen_string_literal: true
module Mustermann
  module Visualizer
    # @!visibility private
    module Highlighter
      # @!visibility private
      module Composite
        extend self

        # @!visibility private
        def highlight?(pattern)
          pattern.is_a? Mustermann::Composite
        end

        # @!visibility private
        def highlight(pattern, renderer)
          operator = " #{pattern.operator} "
          patterns = pattern.patterns.map { |p| highlight_nested(p, renderer) }.join(quote(renderer, operator))
          renderer.pre(:composite) + patterns + renderer.post(:composite)
        end

        # @!visibility private
        def highlight_nested(pattern, renderer)
          highlighter = Highlighter.highlighter_for(pattern)
          if highlighter.respond_to? :nested_highlight
            highlighter.nested_highlight(pattern, renderer)
          else
            type  = quote(renderer, pattern.class.name[/[^:]+$/].downcase + ":", :type)
            quote = quote(renderer, ?")
            type + quote + highlighter.highlight(pattern, renderer) + quote
          end
        end

        # @!visibility private
        def nested_highlight(pattern, renderer)
          quote(renderer, ?() + highlight(pattern, renderer) + quote(renderer, ?))
        end

        # @!visibility private
        def quote(renderer, string, type = :quote)
          renderer.pre(type) + renderer.escape(string, string) + renderer.post(type)
        end
      end
    end
  end
end
