module Mustermann
  # A simple wrapper around ObjectSpace::WeakMap that allows matching keys by equality rather than identity.
  # Used for caching.
  #
  # @see #fetch
  # @!visibility private
  class EqualityMap
    # @!visibility private
    def initialize
      @keys = {}
      @map  = ObjectSpace::WeakMap.new
    end

    # @param [Array<#hash>] key for caching
    # @yield block that will be called to populate entry if missing
    # @return value stored in map or result of block
    # @!visibility private
    def fetch(*key)
      identity = @keys[key.hash]
      key      = identity == key ? identity : key

      # it is ok that this is not thread-safe, worst case it has double cost in
      # generating, object equality is not guaranteed anyways
      @map[key] ||= track(key, yield)
    end

    # @param [#hash] key for identifying the object
    # @param [Object] object to be stored
    # @return [Object] same as the second parameter
    def track(key, object)
      ObjectSpace.define_finalizer(object, finalizer(key.hash))
      @keys[key.hash] = key
      object
    end

    # Finalizer proc needs to be generated in different scope so it doesn't keep a reference to the object.
    #
    # @param [Fixnum] hash for key
    # @return [Proc] finalizer callback
    def finalizer(hash)
      proc { @keys.delete(hash) }
    end

    private :track, :finalizer
  end
end