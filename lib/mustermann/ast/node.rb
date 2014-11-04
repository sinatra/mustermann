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
        @names ||= {}
        #@names.fetch(name) { Object.const_get(constant_name(name)) }
        @names.fetch(name) do
          const_name = constant_name(name)
          const_name.split("::").inject(Object){|current, const| current.const_get(const) }
        end
      end

      # @!visibility private
      def is_a?(type)
        type = Node[type] if type.is_a? Symbol
        super(type)
      end

      # @!visibility private
      # @param [Symbol] name of the node
      # @return [String] qualified name of factory for the node
      def self.constant_name(name)
        return self.name if name.to_sym == :node
        name = name.to_s.split(?_).map(&:capitalize).join
        "#{self.name}::#{name}"
      end

      # Helper for creating a new instance and calling #parse on it.
      # @return [Mustermann::AST::Node]
      # @!visibility private
      def self.parse(*args, &block)
        new(*args).tap { |n| n.parse(&block) }
      end

      # @!visibility private
      def initialize(payload = nil, options = {})
        options, payload = payload, nil if payload.is_a?(Hash)
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

      # Loop through all nodes that don't have child nodes.
      # @!visibility private
      def each_leaf(&block)
        return enum_for(__method__) unless block_given?
        called = false
        Array(payload).each do |entry|
          next unless entry.respond_to? :each_leaf
          entry.each_leaf(&block)
          called = true
        end
        yield(self) unless called
      end

      # @!visibility private
      class Capture < Node
        # @see Mustermann::AST::Compiler::Capture#default
        # @!visibility private
        attr_accessor :constraint

        # @see Mustermann::AST::Compiler::Capture#qualified
        # @!visibility private
        attr_accessor :qualifier

        # @see Mustermann::AST::Pattern#map_param
        # @!visibility private
        attr_accessor :convert

        # @see Mustermann::AST::Node#parse
        # @!visibility private
        def parse
          self.payload ||= ""
          super
        end

        # @!visibility private
        alias_method :name, :payload
      end

      # @!visibility private
      class Char < Node
      end

      # AST node for template expressions.
      # @!visibility private
      class Expression < Node
        # @!visibility private
        attr_accessor :operator
      end

      # @!visibility private
      class Composition < Node
        # @!visibility private
        def initialize(payload = nil, options = {})
          options, payload = payload, nil if payload.is_a?(Hash)
          super(Array(payload), options)
        end
      end

      # @!visibility private
      class Group < Composition
      end

      # @!visibility private
      class Union < Composition
      end

      # @!visibility private
      class Optional < Node
      end

      # @!visibility private
      class Root < Node
        # @!visibility private
        attr_accessor :pattern

        # Will trigger transform.
        #
        # @see Mustermann::AST::Node.parse
        # @!visibility private
        def self.parse(string, &block)
          root         = new
          root.pattern = string
          root.parse(&block)
          root
        end
      end

      # @!visibility private
      class Separator < Node
      end

      # @!visibility private
      class Splat < Capture
        # @see Mustermann::AST::Node::Capture#name
        # @!visibility private
        def name
          "splat"
        end
      end

      # @!visibility private
      class NamedSplat < Splat
        # @see Mustermann::AST::Node::Capture#name
        # @!visibility private
        alias_method :name, :payload
      end

      # AST node for template variables.
      # @!visibility private
      class Variable < Capture
        # @!visibility private
        attr_accessor :prefix, :explode
      end

      # @!visibility private
      class WithLookAhead < Node
        # @!visibility private
        attr_accessor :head, :at_end

        # @!visibility private
        def initialize(payload, at_end)
          self.head, *self.payload = Array(payload)
          self.at_end = at_end
        end
      end
    end
  end
end
