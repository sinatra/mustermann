require 'mustermann/sinatra'

module Mustermann
  # Hybrid pattern type that bridges {Mustermann::Sinatra} and Rails pattern syntax.
  #
  # It supports all syntax elements of {Mustermann::Sinatra}, plus URI template-style
  # placeholders, and changes the semantics of parenthesized groups to match Rails:
  #
  # - A group *without* a pipe operator is **implicitly optional**, even without a
  #   trailing `?`. So `/foo(/bar)` matches both `/foo/bar` and `/foo`.
  #
  # - A group *with* a pipe operator is **not** implicitly optional, to avoid the
  #   ambiguity of `/scope/(a|b)` also matching `/scope/`. Add a trailing `?` to make
  #   such a group optional explicitly: `/scope/(a|b)?`.
  #
  # @example Implicit optional group (no pipe)
  #   require 'mustermann'
  #   pattern = Mustermann.new('/foo(/bar)', type: :hybrid)
  #   pattern === '/foo'     # => true
  #   pattern === '/foo/bar' # => true
  #
  # @example Non-optional group with pipe
  #   pattern = Mustermann.new('/scope/(a|b)', type: :hybrid)
  #   pattern === '/scope/a' # => true
  #   pattern === '/scope/'  # => false
  #
  # @example Explicitly optional group with pipe
  #   pattern = Mustermann.new('/scope/(a|b)?', type: :hybrid)
  #   pattern === '/scope/'  # => true
  #
  # @example Nested implicit optional groups (Rails-style resource routing)
  #   pattern = Mustermann.new('/:controller(/:action(/:id))', type: :hybrid)
  #   pattern.params('/posts')        # => { "controller" => "posts" }
  #   pattern.params('/posts/show')   # => { "controller" => "posts", "action" => "show" }
  #   pattern.params('/posts/show/1') # => { "controller" => "posts", "action" => "show", "id" => "1" }
  #
  # @see Mustermann::Sinatra
  class Hybrid < Sinatra
    register :hybrid

    # Parses a parenthesized group. Groups without a pipe operator are wrapped in an
    # optional node (implicitly optional, Rails style). Groups that do contain a pipe
    # operator are left as plain groups; append `?` to make them optional explicitly.
    on("(") do |c|
      n = node(:group) { read unless scan(?)) }
      has_or = n.payload.any? { |e| e.is_a?(:or) }
      has_or && !scan("?") ? n : node(:optional, n)
    end
  end
end
