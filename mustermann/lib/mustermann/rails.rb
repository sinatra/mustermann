# frozen_string_literal: true
require 'mustermann'
require 'mustermann/ast/pattern'
require 'mustermann/versions'

module Mustermann
  # Rails style pattern implementation.
  #
  # @example
  #   Mustermann.new('/:foo', type: :rails) === '/bar' # => true
  #
  # @see Mustermann::Pattern
  # @see file:README.md#rails Syntax description in the README
  class Rails < AST::Pattern
    extend Versions
    register :rails

    # first parser, no optional parts
    version('2.3') do
      on(nil) { |c| unexpected(c) }
      on(?*)  { |c| node(:named_splat) { scan(/\w+/) } }
      on(?:)  { |c| node(:capture) { scan(/\w+/) } }
    end

    # rack-mount
    version('3.0', '3.1') do
      on(?))  { |c| unexpected(c) }
      on(?()  { |c| node(:optional, node(:group) { read unless scan(?)) }) }
      on(?\\) { |c| node(:char, expect(/./)) }
    end

    # stand-alone journey
    version('3.2') do
      on(?|)  { |c| raise ParseError, "the implementation of | is broken in ActionDispatch, cannot compile compatible pattern" }
      on(?\\) { |c| node(:char, c) }
    end

    # embedded journey, broken (ignored) escapes
    version('4.0', '4.1') { on(?\\) { |c| read } }

    # escapes got fixed in 4.2
    version('4.2') { on(?\\) { |c| node(:char, expect(/./)) } }

    # Rails 5.0 fixes |
    version('5.0') { on(?|) { |c| node(:or) }}
  end
end
