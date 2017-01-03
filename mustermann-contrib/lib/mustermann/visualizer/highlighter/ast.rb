# frozen_string_literal: true
require 'mustermann/ast/translator'

module Mustermann
  module Visualizer
    # @!visibility private
    module Highlighter
      # Provides highlighting for AST based patterns
      # @!visibility private
      class AST
        Index   = Struct.new(:type, :start, :stop, :payload) { undef :to_a }
        Indexer = Mustermann::AST::Translator.create do
          translate(:node)  { |i| Index.new(type, start, stop, Array(t(payload, i)).flatten.compact) }
          translate(Array)  { |i| map { |e| t(e, i) } }
          translate(Object) { |i| }

          translate(:with_look_ahead) do |input|
            [t(head, input), *t(payload, input)]
          end

          translate(:expression) do |input|
            index = Index.new(type, start, stop, Array(t(payload, input)).compact)
            index.payload.delete_if { |e| e.type == :separator }
            index
          end

          translate(:capture) do |input|
            substring   = input[start, length]
            if substart = substring.index(name)
              substart += start
              substop   = substart + name.length
              payload   = [Index.new(:name, substart, substop, [])]
            end
            Index.new(type, start, stop, payload || [])
          end

          translate(:char) do |input|
            substring = input[start, length]
            if payload == substring
              Index.new(type, start, stop, [])
            elsif substart = substring.index(payload)
              substart    += start
              substop      = substart + payload.length
              Index.new(:escaped, start, stop, [Index.new(:escaped_char, substart, substop, [])])
            else
              Index.new(:escaped, start, stop, [])
            end
          end
        end

        private_constant(:Index, :Indexer)

        # @!visibility private
        def self.highlight?(pattern)
          pattern.respond_to? :to_ast
        end

        # @!visibility private
        def self.highlight(pattern, renderer)
          new(pattern, renderer).highlight
        end

        # @!visibility private
        def initialize(pattern, renderer)
          @ast      = pattern.to_ast
          @string   = pattern.to_s
          @renderer = renderer
        end

        # @!visibility private
        def highlight
          index = Indexer.translate(@ast, @string)
          inject_literals(index)
          render(index)
        end

        # @!visibility private
        def render(index)
          return @renderer.escape(@string[index.start..index.stop-1]) if index.type == :literal
          payload = index.payload.map { |i| render(i) }.join
          "#{ @renderer.pre(index.type) }#{ payload }#{ @renderer.post(index.type) }"
        end

        # @!visibility private
        def inject_literals(index)
          start, old_payload, index.payload = index.start, index.payload, []
          old_payload.each do |element|
            index.payload << literal(start, element.start) if start < element.start
            index.payload << element
            inject_literals(element)
            start = element.stop
          end
          index.payload << literal(start, index.stop) if start < index.stop
        end

        # @!visibility private
        def literal(start, stop)
          Index.new(:literal, start, stop, [])
        end
      end
    end
  end
end
