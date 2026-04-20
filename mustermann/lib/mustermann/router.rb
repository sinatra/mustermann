# frozen_string_literal: true
require 'mustermann'
require 'mustermann/set'

module Mustermann
  # An extremely simple, Rack-compatible router implementation using {Mustermann::Set} for pattern matching.
  #
  # @example Basic usage
  #   require 'mustermann/router'
  #
  #   router = Mustermann::Router.new do
  #     get "/hello/:name" do |env|
  #       name = env["mustermann.match"][:name]
  #       [200, { "content-type" => "text/plain" }, ["Hello, #{name}!"]]
  #     end
  #   end
  #
  #   # in config.ru
  #   run router
  #
  # @example Routing to other applications
  #   router = Mustermann::Router.new do
  #     get  "/users",     MyApp::Users::Index
  #     get  "/users/:id", MyApp::Users::Show
  #     post "/users",     MyApp::Users::Create
  #     fallback           MyApp::NotFound
  #   end
  #
  #   router.path_for(MyApp::Users::Show, id: 42) # => "/users/42"
  #
  # @example As middleware
  #   use Mustermann::Router do
  #     get("/up") { [200, { "Content-Type" => "text/plain" }, ["Up!"]] }
  #   end
  #
  #   run MyApp
  #
  # @see Mustermann::Set
  # @see https://rack.github.io/rack/
  class Router
    NOT_FOUND = [404, { "content-type" => "text/plain", "x-cascade" => "pass" }, ["Not found"]].freeze
    VERBS     = %w[GET HEAD POST PUT PATCH DELETE OPTIONS LINK UNLINK].freeze
    private_constant :VERBS, :NOT_FOUND

    # Initializes a new router.
    # @param key [String] The key under which the route match will be stored in the Rack environment hash (default: "mustermann.match").
    # @param options [Hash] Options to be passed to the Mustermann patterns.
    def initialize(fallback = nil, key: "mustermann.match", **options, &block)
      @key      = key
      @sets     = VERBS.to_h { |verb| [verb, Set.new] }
      @options  = options
      @fallback = fallback || ->(env) { NOT_FOUND.dup }

      if block_given?
        instance_exec(&block)
        @sets.each_value(&:optimize!)
      end
    end

    # @param env [Hash] The Rack environment hash for the request.
    # @return [Array] The Rack response array (status, headers, body).
    def call(env)
      if routes = @sets[env["REQUEST_METHOD"]] and match = routes.match(env["PATH_INFO"] || "/")
        env[@key] = match
        return match.value.call(env)
      end
      @fallback.call(env)
    end

    def fallback(fallback = nil, &block) = @fallback = fallback || block || @fallback

    # Adds a route for the given verb and pattern, with the given target.
    #
    # @note Shorthand methods, like `get`, `post`, etc. dynamically are defined for all supported verbs.
    #
    # @param verb [String] HTTP verb (e.g. "GET", "POST")
    # @param pattern [String, Mustermann::Pattern] Pattern string or Mustermann pattern (e.g. "/users/:id")
    # @param target [#call, nil] The Rack application or middleware to call when the route matches. Can be passed a block as well.
    # @yield [env] Block to be used as the target if no explicit target is given.
    # @yieldparam env [Hash] The Rack environment hash for the request.
    # @return [void]
    def route(verb, pattern, target = nil, **options, &block)
      raise ArgumentError, "need to provide target, :to or a block" unless target || block
      raise ArgumentError, "unknown verb: #{verb}" unless VERBS.include?(verb)
      pattern = Mustermann.new(pattern, **@options, **options)
      @sets[verb].add(pattern, target || block)
    end

    # Helps generate links
    #
    # @param app [#call] The Rack application or middleware for which to generate the path.
    # @param (see Mustermann::Expander#expand)
    # @return [String] The generated path.
    def path_for(app, behavior = nil, params = {})
      set = @sets.values.find { |s| s.has_value?(app) } || @sets[VERBS.first]
      set.expand(app, behavior, params)
    end

    VERBS.each do |verb|
      define_method(verb.downcase) { |*args, **opts, &block| route(verb, *args, **opts, &block) }
    end
  end
end
