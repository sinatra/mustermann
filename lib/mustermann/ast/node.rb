module Mustermann
  # @see Mustermann::AST::Pattern
  module AST
    # @!visibility private
    class Node
      # @!visibility private
      attr_accessor :payload

      # @!visibility private
      # @param [Symbol] name of the node
      # @return [Class] factory for the node
      def self.[](name)
        const_get(name.to_s.split(?_).map(&:capitalize).join)
      end

      # Helper for creating a new instance and calling #parse on it.
      # @return [Mustermann::AST::Node]
      # @!visibility private
      def self.parse(*args, &block)
        new(*args).tap { |n| n.parse(&block) }
      end

      # @!visibility private
      def initialize(payload = nil, **options)
        options.each { |key, value| public_send("#{key}=", value) }
        self.payload = payload
      end

      # Double dispatch helper for reading from the buffer into the payload.
      # @!visibility private
      def parse
        self.payload ||= []
        while element = yield
          payload << element
        end
      end

      # @return [String] regular expression corresponding to node
      # @!visibility private
      def compile(options)
        Array(payload).map { |e| e.compile(options) }.join
      end

      # @return [Mustermann::AST::Node] This node after tree transformation. Might be self.
      # @!visibility private
      def transform
        self.payload = payload.transform if payload.respond_to? :transform
        return self unless Array === payload

        new_payload    = []
        with_lookahead = []

        payload.each do |element|
          element = element.transform
          if with_lookahead.empty?
            list = element.expect_lookahead? ? with_lookahead : new_payload
            list << element
          elsif element.lookahead?
            with_lookahead << element
          else
            with_lookahead = [WithLookAhead.new(with_lookahead, false)] if element.separator? and with_lookahead.size > 1
            new_payload.concat(with_lookahead)
            new_payload << element
            with_lookahead.clear
          end
        end

        with_lookahead = [WithLookAhead.new(with_lookahead, true)] if with_lookahead.size > 1
        new_payload.concat(with_lookahead)
        @payload = new_payload
        self
      end

      # @return [Boolean] whether or not the node is a separator (like an unencoded forward slash).
      #   Used for determining look-ahead boundaries
      # @!visibility private
      def separator?
        false
      end

      # @param [Boolean] in_lookahead indicater of parent element can be look-ahead
      # @return [Boolean] whether or not node can be part of look-ahead
      # @!visibility private
      def lookahead?(in_lookahead = false)
        false
      end

      # @return [Boolean] whether or not node expects to be followed by a look-ahead.
      # @!visibility private
      def expect_lookahead?
        false
      end

      # @return [String] Regular expression for matching the given character in all representations
      # @!visibility private
      def encoded(char, uri_decode, space_matches_plus)
        return Regexp.escape(char) unless uri_decode
        uri_parser = URI::Parser.new
        encoded    = uri_parser.escape(char, /./)
        list       = [uri_parser.escape(char), encoded.downcase, encoded.upcase].uniq.map { |c| Regexp.escape(c) }
        list << encoded('+', uri_decode, space_matches_plus) if space_matches_plus and char == " "
        "(?:%s)" % list.join("|")
      end

      # @return [Array<String>] list of names for named captures
      # @!visibility private
      def capture_names
        return payload.capture_names if payload.respond_to? :capture_names
        return [] unless payload.respond_to? :map
        payload.map { |e| e.capture_names if e.respond_to? :capture_names }
      end

      autoload :Capture,       'mustermann/ast/node/capture'
      autoload :Char,          'mustermann/ast/node/char'
      autoload :Expression,    'mustermann/ast/node/expression'
      autoload :Group,         'mustermann/ast/node/group'
      autoload :NamedSplat,    'mustermann/ast/node/named_splat'
      autoload :Optional,      'mustermann/ast/node/optional'
      autoload :Root,          'mustermann/ast/node/root'
      autoload :Separator,     'mustermann/ast/node/separator'
      autoload :Splat,         'mustermann/ast/node/splat'
      autoload :Variable,      'mustermann/ast/node/variable'
      autoload :WithLookAhead, 'mustermann/ast/node/with_look_ahead'
    end
  end
end
