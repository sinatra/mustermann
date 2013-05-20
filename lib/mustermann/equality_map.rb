module Mustermann
  class EqualityMap
    def initialize
      @keys = {}
      @map  = ObjectSpace::WeakMap.new
    end

    def fetch(*key)
      identity = @keys[key.hash]
      key      = identity == key ? identity : key
      @map[key] ||= track(key, yield)
    end

    def track(key, object)
      ObjectSpace.define_finalizer(object, finalizer(hash))
      @keys[key.hash] = key
      object
    end

    def finalizer(hash)
      proc { @keys.delete(hash) }
    end

    private :track, :finalizer
  end
end