# frozen_string_literal: true
require 'hansi'
require 'mustermann'
require 'mustermann/visualizer/highlighter'
require 'mustermann/visualizer/renderer/ansi'
require 'mustermann/visualizer/renderer/hansi_template'
require 'mustermann/visualizer/renderer/html'
require 'mustermann/visualizer/renderer/sexp'

module Mustermann
  module Visualizer
    # Meta class for highlight objects.
    # @see Mustermann::Visualizer#highlight
    class Highlight
      # @!visibility private
      attr_reader :pattern, :theme

      # @!visibility private
      DEFAULT_THEME = Hansi::Theme.new(:solarized,
        default:   :base0,
        separator: :base1,
        escaped:   :base1,
        capture:   :orange,
        name:      :yellow,
        special:   :blue,
        quote:     :red,
        illegal:   :darkred
      )

      # @!visibility private
      BASE_THEME = Hansi::Theme.new(
        special:     :default,
        capture:     :special,
        char:        :default,
        expression:  :capture,
        composition: :special,
        group:       :composition,
        union:       :composition,
        optional:    :special,
        root:        :default,
        separator:   :char,
        splat:       :capture,
        named_splat: :splat,
        variable:    :capture,
        escaped:     :char,
        quote:       :special,
        type:        :special,
        illegal:     :special
      )

      # @!visibility private
      def initialize(pattern, type: nil, inspect: nil, **theme)
        @pattern = Mustermann.new(pattern, type: type)
        @inspect = inspect.nil? ? pattern.is_a?(Mustermann::Composite) : inspect
        theme    = theme.any? ? Hansi::Theme.new(**theme) : DEFAULT_THEME
        @theme   = BASE_THEME.merge(theme)
      end

      # @example
      #   require 'mustermann/visualizer'
      #
      #   pattern   = Mustermann.new('/:name')
      #   highlight = Mustermann::Visualizer.highlight(pattern)
      #
      #   puts highlight.to_hansi_template
      #
      # @return [String] Hansi template representation of the pattern
      def to_hansi_template(**options)
        render_with(Renderer::HansiTemplate, **options)
      end

      # @example
      #   require 'mustermann/visualizer'
      #
      #   pattern   = Mustermann.new('/:name')
      #   highlight = Mustermann::Visualizer.highlight(pattern)
      #
      #   puts highlight.to_ansi
      #
      # @return [String] ANSI colorized version of the pattern
      def to_ansi(**options)
        render_with(Renderer::ANSI, **options)
      end

      # @example
      #   require 'mustermann/visualizer'
      #
      #   pattern   = Mustermann.new('/:name')
      #   highlight = Mustermann::Visualizer.highlight(pattern)
      #
      #   puts highlight.to_html
      #
      # @return [String] HTML rendering of the pattern
      def to_html(**options)
        render_with(Renderer::HTML, **options)
      end

      # @example
      #   require 'mustermann/visualizer'
      #
      #   pattern   = Mustermann.new('/:name')
      #   highlight = Mustermann::Visualizer.highlight(pattern)
      #
      #   puts highlight.to_sexp
      #
      # @return [String] s-expression like representation of the pattern
      def to_sexp(**options)
        render_with(Renderer::Sexp, **options)
      end

      # @return [Mustermann::Pattern] the pattern used to create the highlight object
      def to_pattern
        pattern
      end

      # @return [String] string representation of the pattern
      def to_s
        pattern.to_s
      end

      # @return [String] stylesheet for HTML output from the pattern
      def stylesheet(**options)
        Renderer::HTML.new(self, **options).stylesheet
      end

      # @!visibility private
      def render_with(renderer, **options)
        options[:inspect] = @inspect if options[:inspect].nil?
        renderer.new(self, **options).render
      end

      # @!visibility private
      def render(renderer)
        Highlighter.highlight(pattern, renderer)
      end
    end
  end
end
