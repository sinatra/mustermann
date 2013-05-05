require 'mustermann/ast/node'

module Mustermann
  module AST
    class Node
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
          root.transform
        end

        # @see Mustermann::AST::Node#capture_names
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

        # @see Mustermann::AST::Node#compile
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
    end
  end
end
