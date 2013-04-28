# Namespace and main entry point for the Mustermann library.
#
# Under normal circumstances the only external API entry point you should be using is {Mustermann.new}.
module Mustermann
  # @param [String] string The string representation of the new pattern
  # @param [Hash] options The options hash
  # @return [Mustermann::Pattern] pattern corresponding to string.
  # @see file:README.md#Types_and_Options "Types and Options" in the README
  def self.new(string, type: :sinatra, **options)
    options.any? ? self[type].new(string, **options) : self[type].new(string)
  end

  # @!visibility private
  def self.[](key)
    constant, library = register.fetch(key)
    require library if library
    constant.respond_to?(:new) ? constant : register[key] = const_get(constant)
  end

  # @!visibility private
  def self.register(identifier = nil, constant = identifier.to_s.capitalize, load: "mustermann/#{identifier}")
    @register ||= {}
    @register[identifier] = [constant, load] if identifier
    @register
  end

  # @!visibility private
  def self.extend_object(object)
    return super unless defined? ::Sinatra::Base and object < ::Sinatra::Base
    require 'mustermann/extension'
    object.register Extension
  end

  register :identity
  register :rails
  register :shell
  register :simple
  register :sinatra
  register :template
end