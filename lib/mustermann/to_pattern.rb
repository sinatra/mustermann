require 'mustermann'

module Mustermann
  # Mixin for adding {#to_pattern} ducktyping to objects.
  #
  # @example
  #   require 'mustermann/to_pattern'
  #
  #   class Foo
  #     include Mustermann::ToPattern
  #
  #     def to_s
  #       ":foo/:bar"
  #     end
  #   end
  #
  #   Foo.new.to_pattern # => #<Mustermann::Sinatra:":foo/:bar">
  #
  # By default included into {String}, {Symbol}, {Regexp} and {Mustermann::Pattern}.
  module ToPattern
    # Converts the object into a {Mustermann::Pattern}.
    #
    # @example converting a string
    #   ":name.png".to_pattern # => #<Mustermann::Sinatra:":name.png">
    #
    # @example converting a string with options
    #   "/*path".to_pattern(type: :rails) # => #<Mustermann::Rails:"/*path">
    #
    # @example converting a regexp
    #   /.*/.to_pattern # => #<Mustermann::Regular:".*">
    #
    # @example converting a pattern
    #  Mustermann.new("foo").to_pattern # => #<Mustermann::Sinatra:"foo">
    #
    # @param [Hash] options The options hash.
    # @return [Mustermann::Pattern] pattern corresponding to object.
    def to_pattern(**options)
      Mustermann.new(self, **options)
    end

    append_features String
    append_features Regexp
    append_features Mustermann::Pattern
  end
end
