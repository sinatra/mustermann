require 'mustermann/regexp_based'
require 'strscan'

module Mustermann
  # Superclass for pattern styles that parse an AST from the string pattern.
  # @abstract
  class AST < RegexpBased
    supported_options :capture, :except, :greedy, :space_matches_plus

    # @!visibility private
    class Node
      # @!visibility private
      attr_accessor :payload

      # Helper for creating a new instance and calling #parse on it.
      # @return [Node]
      # @!visibility private
      def self.parse(element = new, &block)
        element.tap { |n| n.parse(&block) }
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

      # @return [Node] This node after tree transformation. Might be self.
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
    end

    # @!visibility private
    class Char < Node
      # @see Node#compile
      # @!visibility private
      def compile(uri_decode: true, space_matches_plus: true, **options)
        encoded(payload, uri_decode, space_matches_plus)
      end

      # @see Node#lookahead?
      # @!visibility private
      def lookahead?(in_lookahead = false)
        in_lookahead
      end

      # @return [String] regexp to be used in lookahead for semi-greedy capturing
      # @!visibility private
      def lookahead(ahead, options)
        ahead + compile(options)
      end
    end

    # @!visibility private
    class Separator < Node
      # @see Node#compile
      # @!visibility private
      def compile(options)
        Regexp.escape(payload)
      end

      # @see Node#separator?
      # @!visibility private
      def separator?
        true
      end
    end

    # @!visibility private
    class Optional < Node
      # @return [String] regexp to be used in lookahead for semi-greedy capturing
      # @!visibility private
      def lookahead(ahead, options)
        payload.lookahead(ahead, options)
      end

      # @see Node#compile
      # @!visibility private
      def compile(options)
        "(?:%s)?" % payload.compile(options)
      end

      # @see Node#lookahead?
      # @!visibility private
      def lookahead?(in_lookahead = false)
        payload.lookahead? true or payload.expect_lookahead?
      end
    end

    # @!visibility private
    class Group < Node
      # @!visibility private
      def initialize(payload = nil, **options)
        super(Array(payload), **options)
      end

      # @see Node#lookahead?
      # @!visibility private
      def lookahead?(in_lookahead = false)
        return false unless payload[0..-2].all? { |e| e.lookahead? in_lookahead }
        payload.last.expect_lookahead? or payload.last.lookahead? in_lookahead
      end

      # Eliminates single element groups.
      #
      # @see Node#transform
      # @!visibility private
      def transform
        payload.size == 1 ? payload.first.transform : super
      end

      # @return [String] regexp to be used in lookahead for semi-greedy capturing
      # @!visibility private
      def lookahead(ahead, options)
        payload.inject(ahead) { |a,e| e.lookahead(a, options) }
      end
    end

    # @!visibility private
    class Capture < Node
      # @see Node#expect_lookahead?
      # @!visibility private
      def expect_lookahead?
        true
      end

      # @see Node#parse
      # @!visibility private
      def parse
        self.payload ||= ""
        super
      end

      # @see Node#capture_names
      # @!visibility private
      def capture_names
        [name]
      end

      # @return [String] name of the capture
      # @!visibility private
      def name
        raise CompileError, "capture name can't be empty" if payload.nil? or payload.empty?
        raise CompileError, "capture name must start with underscore or lower case letter" unless payload =~ /^[a-z_]/
        raise CompileError, "capture name can't be #{payload}" if payload == "splat" or payload == "captures"
        payload
      end

      # @return [String] regexp without the named capture
      # @!visibility private
      def pattern(capture: nil, **options)
        case capture
        when Symbol then from_symbol(capture, **options)
        when Array  then from_array(capture, **options)
        when Hash   then from_hash(capture, **options)
        when String then from_string(capture, **options)
        when nil    then from_nil(**options)
        else capture
        end
      end

      # @return [String] regexp to be used in lookahead for semi-greedy capturing
      # @!visibility private
      def lookahead(ahead, options)
        ahead + pattern(lookahead: ahead, greedy: false, **options).to_s
      end

      # @see Node#compile
      # @!visibility private
      def compile(options)
        return pattern(options) if options[:no_captures]
        "(?<#{name}>#{compile(no_captures: true, **options)})"
      end

      private

        # adds qualifier to a regepx, ie * or *?
        def qualified(string, greedy: true, **options)
          "#{string}+#{?? unless greedy}"
        end

        # default capture if not overridden by config option
        def default(**options)
          "[^/\\?#]"
        end

        # if capture option is not set, qualified default with lookahead
        def from_nil(**options)
          qualified(with_lookahead(default(**options), **options), **options)
        end

        # resolves capture setting depending on name
        def from_hash(hash, **options)
          entry = hash[name.to_sym]
          pattern(capture: entry, **options)
        end

        # creates union of all elements
        def from_array(array, **options)
          array = array.map { |e| pattern(capture: e, **options) }
          Regexp.union(*array)
        end

        # maps symbol to character group
        def from_symbol(symbol, **options)
          qualified(with_lookahead("[[:#{symbol}:]]", **options), **options)
        end

        # direct string matching
        def from_string(string, uri_decode: true, space_matches_plus: true, **options)
          Regexp.new(string.chars.map { |c| encoded(c, uri_decode, space_matches_plus) }.join)
        end

        # adds look-ahead to a regexp string
        def with_lookahead(string, lookahead: nil, **options)
          return string unless lookahead
          "(?:(?!#{lookahead})#{string})"
        end
    end

    # @!visibility private
    class Splat < Capture
      # @see Node#expect_lookahead?
      # @!visibility private
      def expect_lookahead?
        false
      end

      # @see Capture#name
      # @!visibility private
      def name
        "splat"
      end

      # @see Capture#pattern
      # @!visibility private
      def pattern(options)
        ".*?"
      end
    end

    # @!visibility private
    class NamedSplat < Splat
      # @see Capture#name
      # @!visibility private
      alias_method :name, :payload
    end

    # @!visibility private
    class WithLookAhead < Node
      # @!visibility private
      attr_accessor :head, :at_end

      # @!visibility private
      def initialize(payload, at_end)
        self.head, *self.payload = payload
        self.at_end              = at_end
      end

      # @see Node#compile
      # @!visibility private
      def compile(options)
        lookahead = payload.inject('') { |l,e| e.lookahead(l, options) }
        lookahead << (at_end ? '$' : '/')
        head.compile(lookahead: lookahead, **options) + super
      end
    end

    # @!visibility private
    class Root < Node
      # @!visibility private
      attr_accessor :pattern

      # Will trigger transform.
      #
      # @see Node.parse
      # @!visibility private
      def self.parse(string, &block)
        root         = new
        root.pattern = string
        super(root, &block).transform
      end

      # @see Node#capture_names
      # @!visibility private
      def capture_names
        super.flatten
      end

      # Will raise compile error if same capture name is used twice.
      #
      # @!visibility private
      def check_captures
        names = capture_names
        names.delete("splat")
        raise CompileError, "can't use the same capture name twice" if names.uniq != names
      end

      # @see Node#compile
      # @!visibility private
      def compile(except: nil, **options)
        check_captures
        except &&= "(?!#{except}\\Z)"
        Regexp.new("\\A#{except}#{super(options)}\\Z")
      rescue CompileError => e
        e.message << ": #{pattern.inspect}"
        raise e
      end
    end

    # @param [String] string representation of the pattern
    # @return [Mustermann::AST::Root] parse tree representing the pattern
    # @!visibility private
    def parse(string)
      buffer = StringScanner.new(string)
      Root.parse(string) { parse_buffer(buffer) unless buffer.eos? }
    rescue ParseError => e
      e.message << " while parsing #{string.inspect}"
      raise e
    end

    # @param [String] string representation of the pattern
    # @return [Regexp] compiled regexp
    # @see Mustermann::RegexpBased
    # @!visibility private
    def compile(string, except: nil, **options)
      options[:except] = compile(except, no_captures: true, **options) if except
      parse(string).compile(options)
    end

    # Parses one element from buffer, including suffix.
    #
    # @param [StringScanner] buffer to read from
    # @return [Mustermann::AST::Node] element read from buffer
    # @!visibility private
    def parse_buffer(buffer)
      parse_suffix(parse_element(buffer), buffer)
    end

    # Parses one element from buffer, excluding suffix.
    #
    # @note Must be overridden by subclass.
    # @param [StringScanner] buffer to read from
    # @return [Mustermann::AST::Node] element read from buffer
    # @!visibility private
    def parse_element(buffer)
      raise NotImplementedError, 'subclass responsibility'
    end


    # Allows modifying an element based on a suffix that might still be buffered.
    #
    # @note Can be overridden by subclass.
    # @param [Mustermann::AST::Node] element last parsed from buffer
    # @param [StringScanner] buffer to read from
    # @return [Mustermann::AST::Node] element read from buffer
    # @!visibility private
    def parse_suffix(element, buffer)
      element
    end

    # Helper for raising an exception for an unexpected character.
    # Will read character from buffer if buffer is passed in.
    #
    # @param [String, StringScanner, nil] char the unexcpected character
    # @raise [ParseError, Exception]
    # @!visibility private
    def unexpected(char, exception: ParseError)
      char = char.getch if char.respond_to? :getch
      char = "space" if char == " "
      raise exception, "unexpected #{char || "end of string"}"
    end

    # Asserts a regular expression matches what's next on the buffer.
    # Will return corresponding MatchData if regexp includes named captures.
    #
    # @param [StringScanner] buffer to parse from
    # @param [Regexp] regexp expected to match
    # @return [String, MatchData] the match
    # @raise [ParseError] if expectation wasn't met
    # @!visibility private
    def expect(buffer, regexp, **options)
      regexp = Regexp.new Regexp.escape(regexp.to_str) unless regexp.is_a? Regexp
      string = buffer.scan(regexp) || unexpected(buffer, **options)
      regexp.names.any? ? regexp.match(string) : string
    end

    private :parse, :compile, :parse_buffer, :parse_element, :parse_suffix, :unexpected, :expect
    private_constant :Node, :Char, :Separator, :Optional, :Group, :Capture, :Splat, :NamedSplat, :WithLookAhead, :Root
  end
end
