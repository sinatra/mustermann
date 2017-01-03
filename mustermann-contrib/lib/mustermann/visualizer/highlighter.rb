# frozen_string_literal: true
require 'mustermann/visualizer/highlighter/ast'
require 'mustermann/visualizer/highlighter/ad_hoc'
require 'mustermann/visualizer/highlighter/composite'
require 'mustermann/visualizer/highlighter/dummy'
require 'mustermann/visualizer/highlighter/regular'

module Mustermann
  module Visualizer
    # @!visibility private
    module Highlighter
      extend self

      # @return [String] highlighted string
      # @!visibility private
      def highlight(pattern, renderer)
        highlighter_for(pattern).highlight(pattern, renderer)
      end

      # @return [#highlight] Highlighter for given pattern
      # @!visibility private
      def highlighter_for(pattern)
        return pattern.highlighter if pattern.respond_to? :highlighter and pattern.highlighter
        consts      = constants.map { |name| const_get(name) }
        highlighter = consts.detect { |c| c.respond_to? :highlight? and c.highlight? pattern }
        highlighter || Dummy
      end

      # Used to generate highlighting rules on the fly.
      # @see {Mustermann::Shell#highlighter}
      # @see {Mustermann::Simple#highlighter}
      # @!visibility private
      def create(&block)
        Class.new(AdHoc, &block)
      end
    end
  end
end
