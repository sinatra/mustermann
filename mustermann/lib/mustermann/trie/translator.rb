# frozen_string_literal: true
require 'mustermann/trie/node'
require 'mustermann/ast/translator'

module Mustermann
  class Trie
    class Translator < AST::Translator
      class NodeTranslator < AST::Translator::NodeTranslator
        def compile(**options)
          regexp = translator.compiler.translate(node, **translator.options, **options)
          /\A#{regexp}/
        end
      end

      raises TrieError

      translate(:root)      { |n, **o| t(payload, n, **o)   }
      translate(:capture)   { |n, **o| Node.new(compile, n) }
      translate(:separator) { |n, **o| Node.new(payload, n) }

      translate(:char) do |nested, **options|
        nodes = t.possible_strings(payload).map { |s| Node.new(s, nested) }
        return nested unless nodes.any?
        nodes.reduce(:merge)
      end

      translate(Array) do |nested, **options|
        return nested if empty?
        t(first, t(self[1..-1], nested, **options), **options)
      end

      attr_reader :compiler, :options

      def initialize(compiler, **options)
        @compiler = compiler.new
        @options  = options
        super()
      end

      def translate(node, nested = nil, **options)
        nested ||= Node.new(**options)
        super
      end

      def possible_strings(char)
        return [] if char.empty?
        return [char] if options[:uri_decode] == false
        encoded = escape(char, escape: /./)
        strings = [escape(char), encoded.upcase, encoded.downcase]
        strings += possible_strings("+") + [" "] if char == " " and options[:space_matches_plus] != false
        strings.uniq
      end
    end

    private_constant :Translator
  end
end
