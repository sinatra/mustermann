# frozen_string_literal: true
require 'mustermann'
require 'mustermann/ast/pattern'

module Mustermann
  # Flask style pattern implementation.
  #
  # @example
  #   Mustermann.new('/<foo>', type: :flask) === '/bar' # => true
  #
  # @see Mustermann::Pattern
  # @see file:README.md#flask Syntax description in the README
  class Flask < AST::Pattern
    include Concat::Native
    register :flask

    on(nil, ?>, ?:) { |c| unexpected(c) }

    on(?<) do |char|
      converter_name       = expect(/\w+/, char: char)
      args, opts           = scan(?() ? read_args(?=, ?)) : [[], {}]

      if scan(?:)
        name = read_escaped(?>)
      else
        converter_name, name = 'default', converter_name
        expect(?>)
      end

      converter   = pattern.converters.fetch(converter_name) { unexpected("converter %p" % converter_name) }
      converter   = converter.new(*args, **opts)  if converter.respond_to? :new
      constraint  = converter.constraint          if converter.respond_to? :constraint
      convert     = converter.convert             if converter.respond_to? :convert
      qualifier   = converter.qualifier           if converter.respond_to? :qualifier
      node_type   = converter.node_type           if converter.respond_to? :node_type
      node_type ||= :capture

      node(node_type, name, convert: convert, constraint: constraint, qualifier: qualifier)
    end

    # A class for easy creating of converters.
    # @see Mustermann::Flask#register_converter
    class Converter
      # Constraint on the format used for the capture.
      # Should be a regexp (or a string corresponding to a regexp)
      # @see Mustermann::Flask#register_converter
      attr_accessor :constraint

      # Callback
      # Should be a Proc.
      # @see Mustermann::Flask#register_converter
      attr_accessor :convert

      # Constraint on the format used for the capture.
      # Should be a regexp (or a string corresponding to a regexp)
      # @see Mustermann::Flask#register_converter
      # @!visibility private
      attr_accessor :node_type

      # Constraint on the format used for the capture.
      # Should be a regexp (or a string corresponding to a regexp)
      # @see Mustermann::Flask#register_converter
      # @!visibility private
      attr_accessor :qualifier

      # @!visibility private
      def self.create(&block)
        Class.new(self) do
          define_method(:initialize) { |*a, **o| block[self, *a, **o] }
        end
      end

      # Makes sure a given value falls inbetween a min and a max.
      # Uses the passed block to convert the value from a string to whatever
      # format you'd expect.
      #
      # @example
      #   require 'mustermann/flask'
      #
      #   class MyPattern < Mustermann::Flask
      #     register_converter(:x) { between(5, 15, &:to_i) }
      #   end
      #
      #   pattern = MyPattern.new('<x:id>')
      #   pattern.params('/12') # => { 'id' => 12 }
      #   pattern.params('/16') # => { 'id' => 15 }
      #
      # @see Mustermann::Flask#register_converter
      def between(min, max)
        self.convert = proc do |input|
          value = yield(input)
          value = yield(min) if min and value < yield(min)
          value = yield(max) if max and value > yield(max)
          value
        end
      end
    end

    # Generally available converters.
    # @!visibility private
    def self.converters(inherited = true)
      return @converters ||= {} unless inherited
      defaults = superclass.respond_to?(:converters) ? superclass.converters : {}
      defaults.merge(converters(false))
    end

    # Allows you to register your own converters.
    #
    # It is reommended to use this on a subclass, so to not influence other subsystems
    # using flask templates.
    #
    # The object passed in as converter can implement #convert and/or #constraint.
    #
    # It can also instead implement #new, which will then return an object responding
    # to some of these methods. Arguments from the flask pattern will be passed to #new.
    #
    # If passed a block, it will be yielded to with a {Mustermann::Flask::Converter}
    # instance and any arguments in the flask pattern.
    #
    # @example with simple object
    #   require 'mustermann/flask'
    #
    #   MyPattern    = Class.new(Mustermann::Flask)
    #   up_converter = Struct.new(:convert).new(:upcase.to_proc)
    #   MyPattern.register_converter(:upper, up_converter)
    #
    #   MyPattern.new("/<up:name>").params('/foo') # => { "name" => "FOO" }
    #
    # @example with block
    #   require 'mustermann/flask'
    #
    #   MyPattern    = Class.new(Mustermann::Flask)
    #   MyPattern.register_converter(:upper) { |c| c.convert = :upcase.to_proc }
    #
    #   MyPattern.new("/<up:name>").params('/foo') # => { "name" => "FOO" }
    #
    # @example with converter class
    #   require 'mustermann/flasl'
    #
    #   class MyPattern < Mustermann::Flask
    #     class Converter
    #       attr_reader :convert
    #       def initialize(send: :to_s)
    #         @convert = send.to_sym.to_proc
    #       end
    #     end
    #
    #     register_converter(:t, Converter)
    #   end
    #
    #   MyPattern.new("/<t(send=upcase):name>").params('/Foo')   # => { "name" => "FOO" }
    #   MyPattern.new("/<t(send=downcase):name>").params('/Foo') # => { "name" => "foo" }
    #
    # @param [#to_s] name converter name
    # @param [#new, #convert, #constraint, nil] converter
    def self.register_converter(name, converter = nil, &block)
      converter ||= Converter.create(&block)
      converters(false)[name.to_s] = converter
    end

    register_converter(:string) do |converter, minlength: nil, maxlength: nil, length: nil|
      converter.qualifier = "{%s,%s}" % [minlength || 1, maxlength] if minlength or maxlength
      converter.qualifier = "{%s}"    % length if length
    end

    register_converter(:int) do |converter, min: nil, max: nil, fixed_digits: false|
      converter.constraint = /\d/
      converter.qualifier  = "{#{fixed_digits}}" if fixed_digits
      converter.between(min, max) { |string| Integer(string) }
    end

    register_converter(:float) do |converter, min: nil, max: nil|
      converter.constraint = /\d*\.?\d+/
      converter.qualifier  = ""
      converter.between(min, max) { |string| Float(string) }
    end

    register_converter(:path) do |converter|
      converter.node_type = :named_splat
    end

    register_converter(:any) do |converter, *strings|
      strings              = strings.map { |s| Regexp.escape(s) unless s == {} }.compact
      converter.qualifier  = ""
      converter.constraint = Regexp.union(*strings)
    end

    register_converter(:default, converters['string'])

    supported_options :converters
    attr_reader :converters

    def initialize(input, converters: {}, **options)
      @converters = self.class.converters.dup
      converters.each { |k,v| @converters[k.to_s] = v } if converters
      super(input, **options)
    end
  end
end
