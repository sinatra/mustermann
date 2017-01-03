# frozen_string_literal: true
require 'strscan'

module Mustermann
  module Visualizer
    # @!visibility private
    module Highlighter
      # Used to generate highlighting rules on the fly.
      # @see {Mustermann::Shell#highlighter}
      # @see {Mustermann::Simple#highlighter}
      # @!visibility private
      class AdHoc
        # @!visibility private
        def self.highlight(pattern, renderer)
          new(pattern, renderer).highlight
        end

        # @!visibility private
        def self.rules
          @rules ||= {}
        end

        # @!visibility private
        def self.on(regexp, type = nil, &callback)
          return regexp.map  { |key, value| on(key, value, &callback) } if regexp.is_a? Hash
          raise ArgumentError, 'needs type or callback' unless type or callback
          callback    ||= proc { |matched| element(type, matched) }
          regexp        = Regexp.new(Regexp.escape(regexp)) unless regexp.is_a? Regexp
          rules[regexp] = callback
        end

        # @!visibility private
        attr_reader :pattern, :renderer, :rules, :output, :scanner
        def initialize(pattern, renderer)
          @pattern  = pattern
          @renderer = renderer
          @output   = String.new
          @rules    = self.class.rules
          @scanner  = ::StringScanner.new(pattern.to_s)
        end

        # @!visibility private
        def highlight(stop = /\Z/)
          output << renderer.pre(:root)
          until scanner.eos? or scanner.check(stop)
            position = scanner.pos
            apply(scanner)
            read_char(scanner) if position == scanner.pos and not scanner.check(stop)
          end
          output << renderer.post(:root)
        end

        # @!visibility private
        def apply(scanner)
          rules.each do |regexp, callback|
            next unless result = scanner.scan(regexp)
            instance_exec(result, &callback)
          end
        end

        # @!visibility private
        def read_char(scanner)
          return unless char = scanner.getch
          type = char == ?/ ? :separator : :char
          element(type, char)
        end

        # @!visibility private
        def escaped(content = ?\\, char)
          element(:escaped, content) { element(:escaped_char, char) }
        end

        # @!visibility private
        def nested(type, opening, closing, *separators)
          element(type, opening) do
            char = nil
            until char == closing or scanner.eos?
              highlight(Regexp.union(closing, *separators))
              char = scanner.getch
              output << char if char
            end
          end
        end

        # @!visibility private
        def element(type, content = nil)
          output << renderer.pre(type)
          output << renderer.escape(content) if content
          yield if block_given?
          output << renderer.post(type)
        end
      end
    end
  end
end
