require 'mustermann/ast/node'
require 'forwardable'
require 'strscan'

module Mustermann
  # @see Mustermann::AST::Pattern
  module AST
    # Simple, StringScanner based parser.
    # @!visibility private
    class Parser
      # @param [String] string to be parsed
      # @return [Mustermann::AST::Node] parse tree for string
      # @!visibility private
      def self.parse(string)
        new.parse(string)
      end

      # Defines another grammar rule for first character.
      #
      # @see Mustermann::Rails
      # @see Mustermann::Sinatra
      # @see Mustermann::Template
      # @!visibility private
      def self.on(*chars, &block)
        chars.each do |char|
          define_method("read %p" % char, &block)
        end
      end

      # Defines another grammar rule for a suffix.
      #
      # @see Mustermann::Sinatra
      # @!visibility private
      def self.suffix(pattern = /./, &block)
        @suffix ||= []
        @suffix << [pattern, block] if block
        @suffix
      end

      # @!visibility private
      attr_reader :buffer, :string

      extend Forwardable
      def_delegators :buffer, :eos?, :getch

      # @param [String] string to be parsed
      # @return [Mustermann::AST::Node] parse tree for string
      # @!visibility private
      def parse(string)
        @string = string
        @buffer = StringScanner.new(string)
        node(:root, string) { read unless eos? }
      end

      # @example
      #   node(:char, 'x').compile =~ 'x' # => true
      #
      # @param [Symbol] type node type
      # @return [Mustermann::AST::Node]
      # @!visibility private
      def node(type, *args, &block)
        type = Node[type] unless type.respond_to? :new
        block ? type.parse(*args, &block) : type.new(*args)
      end

      # Create a node for a character we don't have an explicit rule for.
      #
      # @param [String] char the character
      # @return [Mustermann::AST::Node] the node
      # @!visibility private
      def default_node(char)
        char == ?/ ? node(:separator, char) : node(:char, char)
      end

      # Reads the next element from the buffer.
      # @return [Mustermann::AST::Node] next element
      # @!visibility private
      def read
        char    = getch
        method  = "read %p" % char
        element = respond_to?(method) ? send(method, char) : default_node(char)
        read_suffix(element)
      end

      # Checks for a potential suffix on the buffer.
      # @param [Mustermann::AST::Node] element node without suffix
      # @return [Mustermann::AST::Node] node with suffix
      # @!visibility private
      def read_suffix(element)
        self.class.suffix.inject(element) do |ele, (regexp, callback)|
          next ele unless payload = scan(regexp)
          instance_exec(payload, ele, &callback)
        end
      end

      # Wrapper around {StringScanner#scan} that turns strings into escaped
      # regular expressions and returns a MatchData if the regexp has any
      # named captures.
      #
      # @param [Regexp, String] regexp
      # @see StringScanner#scan
      # @return [String, MatchData, nil]
      # @!visibility private
      def scan(regexp)
        regexp = Regexp.new(Regexp.escape(regexp)) unless regexp.is_a? Regexp
        string = buffer.scan(regexp)
        regexp.names.any? ? regexp.match(string) : string
      end

      # Asserts a regular expression matches what's next on the buffer.
      # Will return corresponding MatchData if regexp includes named captures.
      #
      # @param [Regexp] regexp expected to match
      # @return [String, MatchData] the match
      # @raise [Mustermann::ParseError] if expectation wasn't met
      # @!visibility private
      def expect(regexp, options = {})
        scan(regexp)|| unexpected(options)
      end

      # Helper for raising an exception for an unexpected character.
      # Will read character from buffer if buffer is passed in.
      #
      # @param [String, nil] char the unexpected character
      # @raise [Mustermann::ParseError, Exception]
      # @!visibility private
      def unexpected(char = getch, options = {})
        options, char = char, getch if char.is_a?(Hash)
        exception = options.fetch(:exception, ParseError)
        char = "space" if char == " "
        raise exception, "unexpected #{char || "end of string"} while parsing #{string.inspect}"
      end
    end

    private_constant :Parser
  end
end
