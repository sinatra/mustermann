require 'mustermann/router/simple'

module Mustermann
  module Router
    # Simple pattern based router that allows matching paths to a given Rack application.
    #
    # @example config.ru
    #    router = Mustermann::Rack.new do
    #      on '/' do |env|
    #        [200, {'Content-Type' => 'text/plain'}, ['Hello World!']]
    #      end
    #
    #      on '/:name' do |env|
    #        name = env['mustermann.params']['name']
    #        [200, {'Content-Type' => 'text/plain'}, ["Hello #{name}!"]]
    #      end
    #
    #      on '/something/*', call: SomeApp
    #    end
    #
    #    # in a config.ru
    #    run router
    class Rack < Simple
      def initialize(options = {}, &block)
        env_prefix  = options.delete(:env_prefix) || "mustermann"
        params_key  = options.delete(:params_key) || "#{env_prefix}.params"
        pattern_key = options.delete(:pattern_key) || "#{env_prefix}.pattern"
        @params_key, @pattern_key = params_key, pattern_key
        options[:default] = [404, {"Content-Type" => "text/plain", "X-Cascade" => "pass"}, ["Not Found"]] unless options.include? :default
        super(options, &block)
      end

      def invoke(callback, env, params, pattern)
        params_was, pattern_was             = env[@params_key], env[@pattern_key]
        env[@params_key], env[@pattern_key] = params, pattern
        response = callback.call(env)
        response[1].each { |k,v| throw :pass if k.downcase == 'x-cascade' and v == 'pass' }
        response
      ensure
        env[@params_key], env[@pattern_key] = params_was, pattern_was
      end

      def string_for(env)
        env['PATH_INFO']
      end

      private :invoke, :string_for
    end
  end
end
