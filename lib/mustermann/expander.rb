require 'mustermann/ast/expander'
require 'mustermann'

module Mustermann
  class Expander
    attr_reader :patterns, :additional_values

    def initialize(*patterns, additional_values: :raise, **options)
      unless additional_values == :raise or additional_values == :ignore or additional_values == :append
        raise ArgumentError, "Illegal value %p for additional_values" % additional_values
      end

      @patterns          = []
      @api_expander      = Mustermann::AST::Expander.new
      @additional_values = additional_values
      @options           = options
      add(*patterns)
    end

    def add(*patterns)
      patterns.each do |pattern|
        pattern = Mustermann.new(pattern.to_str, **@options) if pattern.respond_to? :to_str
        raise NotImplementedError, "expanding not supported for #{pattern.class}" unless pattern.respond_to? :to_ast
        @api_expander.add(pattern.to_ast)
        @patterns << pattern
      end
      self
    end

    alias_method :<<, :add

    def expand(behavior = nil, **values)
      case behavior || additional_values
      when :raise  then @api_expander.expand(values)
      when :ignore then with_rest(values) { |uri, rest| uri }
      when :append then with_rest(values) { |uri, rest| append(uri, rest) }
      else raise ArgumentError, "unknown behavior %p" % behavior
      end
    end

    def with_rest(values)
      expandable     = @api_expander.expandable_keys(values.keys)
      non_expandable = values.keys - expandable
      yield expand(:raise, slice(values, expandable)), slice(values, non_expandable)
    end

    def slice(hash, keys)
      Hash[keys.map { |k| [k, hash[k]] }]
    end

    def append(uri, values)
      return uri unless values and values.any?
      entries = values.map { |pair| pair.map { |e| @api_expander.escape(e, also_escape: /[\/\?#\&\=%]/) }.join(?=) }
      "#{ uri }#{ uri[??]??&:?? }#{ entries.join(?&) }"
    end

    private :with_rest, :slice, :append
  end
end
