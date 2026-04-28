# frozen_string_literal: true
module Mustermann
  class Sinatra < AST::Pattern
    # Tries to translate objects to Sinatra patterns.
    # @!visibility private
    class TryConvert < AST::Translator
      # @return [Mustermann::Sinatra, nil]
      # @!visibility private
      def self.convert(type, input, **options)
        new(type, **options).translate(input)
      end

      # Reserved variable names.
      # @!visibility private
      attr_reader :names

      # Expected options for the resulting pattern.
      # @!visibility private
      attr_reader :options

      # Expected pattern type for the resulting pattern.
      # @!visibility private
      attr_reader :type

      # @!visibility private
      def initialize(type, names: EMPTY_ARRAY, **options)
        @names   = names
        @options = options
        @type    = type
      end

      # @return [Mustermann::Sinatra]
      # @!visibility private
      def new(input, escape: false, **opts)
        input = Mustermann::Sinatra.escape(input) if escape
        type.new(input, **opts, **options, ignore_unknown_options: true)
      end

      # @return [true, false] whether or not expected pattern should have uri_decode option set
      # @!visibility private
      def uri_decode
        options.fetch(:uri_decode, true)
      end

      # @return [true, false] whether or not the given options are compatible with the expected options
      # @!visibility private
      def compatible_options?(other_options)
        other_options.all? do |key, value|
          case key
          when :capture then compatible_capture_option?(value)
          else value == options[key]
          end
        end
      end

      # @return [true, false] whether or not the given capture option is compatible with the expected capture option
      # @!visibility private
      def compatible_capture_option?(capture)
        return true if names.empty?
        case capture
        when Hash  then capture.all? { |n, o| !names.include?(n.to_s) and compatible_capture_option?(o) }
        when Array then capture.all? { |o| compatible_capture_option?(o) }
        else true
        end
      end

      translate(Object) { nil }
      translate(String) { t.new(self, escape: true) }
      translate(Identity) { t.new(self, escape: true) if uri_decode == t.uri_decode }

      translate(Sinatra) do
        if node.class == t.type and t.options == options
          node
        elsif t.compatible_options? options
          t.new(to_s, **options)
        end
      end

      translate AST::Pattern do
        next unless t.compatible_options? options
        t.new(SafeRenderer.translate(to_ast), **options) rescue nil
      end
    end

    private_constant :TryConvert
  end
end
