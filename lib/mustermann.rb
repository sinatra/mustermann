require 'mustermann/pattern'
require 'mustermann/composite'

# Namespace and main entry point for the Mustermann library.
#
# Under normal circumstances the only external API entry point you should be using is {Mustermann.new}.
module Mustermann
  # Creates a new pattern based on input.
  #
  # * From {Mustermann::Pattern}: returns given pattern.
  # * From String: creates a pattern from the string, depending on type option (defaults to {Mustermann::Sinatra})
  # * From Regexp: creates a {Mustermann::Regular} pattern.
  # * From Symbol: creates a {Mustermann::Sinatra} pattern with a single named capture named after the input.
  # * From an Array or multiple inputs: creates a new pattern from each element, combines them to a {Mustermann::Composite}.
  # * From anything else: Will try to call to_pattern on it or raise a TypeError.
  #
  # Note that if the input is a {Mustermann::Pattern}, Regexp or Symbol, the type option is ignored and if to_pattern is
  # called on the object, the type will be handed on but might be ignored by the input object.
  #
  # If you want to enforce the pattern type, you should create them via their expected class.
  #
  # @example creating patterns
  #   require 'mustermann'
  #
  #   Mustermann.new("/:name")                    # => #<Mustermann::Sinatra:"/example">
  #   Mustermann.new("/{name}", type: :template)  # => #<Mustermann::Template:"/{name}">
  #   Mustermann.new(/.*/)                        # => #<Mustermann::Regular:".*">
  #   Mustermann.new(:name, capture: :word)       # => #<Mustermann::Sinatra:":name">
  #   Mustermann.new("/", "/*.jpg", type: :shell) # => #<Mustermann::Composite:(shell:"/" | shell:"/*.jpg")>
  #
  # @example using custom #to_pattern
  #   require 'mustermann'
  #
  #   class MyObject
  #     def to_pattern(**options)
  #       Mustermann.new("/:name", **options)
  #     end
  #   end
  #
  #   Mustermann.new(MyObject.new, type: :rails) # => #<Mustermann::Rails:"/:name">
  #
  # @example enforcing type
  #   require 'mustermann/sinatra'
  #
  #   Mustermann::Sinatra.new("/:name")
  #
  # @param [String, Pattern, Regexp, Symbol, #to_pattern, Array<String, Pattern, Regexp, Symbol, #to_pattern>]
  #   input The representation of the pattern
  # @param [Hash] options The options hash
  # @return [Mustermann::Pattern] pattern corresponding to string.
  # @raise (see [])
  # @raise (see Mustermann::Pattern.new)
  # @raise [TypeError] if the passed object cannot be converted to a pattern
  # @see file:README.md#Types_and_Options "Types and Options" in the README
  def self.new(*input)
    options = input.last.kind_of?(Hash) ? input.pop : {}
    type = options.delete(:type) || :sinatra
    input = input.first if input.size < 2
    case input
    when Pattern then input
    when Regexp  then self[:regexp].new(input, options)
    when String  then self[type].new(input, options)
    when Array   then Composite.new(input, options.merge(:type => type))
    when Symbol  then self[:sinatra].new(input.inspect, options)
    else
      pattern = input.to_pattern(options.merge(:type => type)) if input.respond_to? :to_pattern
      raise TypeError, "#{input.class} can't be coerced into Mustermann::Pattern" if pattern.nil?
      pattern
    end
  end

  # Maps a type to its factory.
  #
  # @example
  #   Mustermann[:sinatra] # => Mustermann::Sinatra
  #
  # @param [Symbol] key a pattern type identifier
  # @raise [ArgumentError] if the type is not supported
  # @return [Class, #new] pattern factory
  def self.[](key)
    constant, library = register.fetch(key) { raise ArgumentError, "unsupported type %p" % key }
    require library if library
    constant.respond_to?(:new) ? constant : register[key] = const_get(constant)
  end

  # @!visibility private
  def self.register(*identifiers)
    options  = identifiers.last.is_a?(Hash) ? identifiers.pop : {}
    constant = options[:constant] || identifiers.first.to_s.capitalize
    load     = options[:load] || "mustermann/#{identifiers.first}"
    @register ||= {}
    identifiers.each { |i| @register[i] = [constant, load] }
    @register
  end

  # @!visibility private
  def self.extend_object(object)
    return super unless defined? ::Sinatra::Base and object.is_a? Class and object < ::Sinatra::Base
    require 'mustermann/extension'
    object.register Extension
  end

  register :identity
  register :rails
  register :regular, :regexp
  register :shell
  register :simple
  register :sinatra
  register :template
end
