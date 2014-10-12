require 'mustermann/pattern'
require 'mustermann/composite'

# Namespace and main entry point for the Mustermann library.
#
# Under normal circumstances the only external API entry point you should be using is {Mustermann.new}.
module Mustermann
  # @param [String, Pattern, Regexp, #to_pattern, Array<String, Pattern, Regexp, #to_pattern>]
  #   input The representation of the new pattern
  # @param [Hash] options The options hash
  # @return [Mustermann::Pattern] pattern corresponding to string.
  # @raise (see [])
  # @raise (see Mustermann::Pattern.new)
  # @raise [TypeError] if the passed object cannot be converted to a pattern
  # @see file:README.md#Types_and_Options "Types and Options" in the README
  def self.new(*input, type: :sinatra, **options)
    input = input.first if input.size < 2
    case input
    when Pattern then input
    when Regexp  then self[:regexp].new(input, **options)
    when String  then self[type].new(input, **options)
    when Array   then Composite.new(input, type: type, **options)
    else
      pattern = input.to_pattern(type: type, **options) if input.respond_to? :to_pattern
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
  def self.register(*identifiers, constant: identifiers.first.to_s.capitalize, load: "mustermann/#{identifiers.first}")
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