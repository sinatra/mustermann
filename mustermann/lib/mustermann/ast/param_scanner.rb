# frozen_string_literal: true
require 'mustermann/ast/converters'
require 'mustermann/ast/translator'

module Mustermann
  module AST
    # Scans an AST for param converters.
    # @!visibility private
    # @see Mustermann::AST::Pattern#to_templates
    class ParamScanner < Translator
      # @!visibility private
      def self.scan_params(ast, options)
        new.translate(ast, options)
      end

      translate(:node)             { |o| t(payload, o) }
      translate(:with_look_ahead)  { |o| t(head, o).merge(t(payload, o)) }
      translate(Array)             { |o| map { |e| t(e, o) }.inject(:merge) }
      translate(Object)            { |o| {} }

      class Capture < NodeTranslator
        register :capture

        def translate(options)
          return { name => convert } if convert
          _, converter = converter(options[:capture])
          converter ? { name => converter } : {}
        end

        def converter(capture)
          case capture
          when Hash   then return converter(capture[name.to_sym])
          when Class  then regexp, converter = CONVERTERS[capture.name]
          when Symbol then regexp, converter = CONVERTERS[capture]
          when Array
            entries = capture.map { |item| converter(item) }.compact
            regexp  = Regexp.union(entries.map(&:first))

            entries.map! { |r, c| [/\A#{r}\Z/, c] }

            converter = ->(string) do
              _, c = entries.find { |r, _| r.match?(string) }
              c&.call(string) || string
            end
          end

          return unless converter
          [regexp, converter.to_proc]
        end
      end
    end
  end
end
