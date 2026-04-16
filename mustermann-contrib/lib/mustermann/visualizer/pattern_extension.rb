# frozen_string_literal: true
module Mustermann
  module Visualizer
    # Mixin that will be added to {Mustermann::Pattern}.
    module PatternExtension
      prepend_features Composite
      prepend_features Pattern

      # @example
      #   puts Mustermann.new("/:page").to_ansi
      #
      # @return [String] ANSI colorized version of the pattern.
      def to_ansi(inspect: nil, **theme)
        Visualizer.highlight(self, **theme).to_ansi(inspect: inspect)
      end

      # @example
      #   puts Mustermann.new("/:page").to_html
      #
      # @return [String] HTML version of the pattern.
      def to_html(inspect: nil, tag: :span, class_prefix: "mustermann_", css: :inline, **theme)
        Visualizer.highlight(self, **theme).to_html(inspect: inspect, tag: tag, class_prefix: class_prefix, css: css)
      end

      # @example
      #   puts Mustermann.new("/:page").to_tree
      #
      # @return [String] tree version of the pattern.
      def to_tree
        Visualizer.tree(self).to_s
      end

      # If invoked directly by puts: ANSI colorized version of the pattern.
      # If invoked by anything else: String version of the pattern.
      #
      # @example
      #   require 'mustermann/visualizer'
      #   pattern = Mustermann.new('/:page')
      #   puts pattern        # will have color
      #   puts pattern.to_s   # will not have color
      #
      # @return [String] non-colorized or colorized version of the pattern
      def to_s
        caller_locations.first.label == 'puts' ? to_ansi : super
      end

      # @return [String] ANSI colorized version of {Mustermann::Pattern#inspect}
      def color_inspect(base_color = nil, **theme)
        base_color ||= Highlight::DEFAULT_THEME[:base01]
        template = is_a?(Composite) ? "*#<%p:(*%s*)>*" : "*#<%p:*%s*>*"
        Hansi.render(template, self.class, to_ansi(inspect: true, **theme), {"*" => base_color})
      end
    end
  end
end
