# frozen_string_literal: true
module Mustermann
  # Class for pattern objects composed of multiple patterns using binary logic.
  # @see Mustermann::Pattern#&
  # @see Mustermann::Pattern#|
  # @see Mustermann::Pattern#^
  class Composite < Pattern
    attr_reader :patterns, :operator
    supported_options :operator, :type

    # @see Mustermann::Pattern.supported?
    def self.supported?(option, type: nil, **options)
      return true if super
      Mustermann[type || Mustermann::DEFAULT_TYPE].supported?(option, **options)
    end

    # @return [Mustermann::Pattern] a new composite pattern
    def self.new(*patterns, **options)
      patterns = patterns.flatten
      case patterns.size
      when 0 then raise ArgumentError, 'cannot create empty composite pattern'
      when 1 then patterns.first
      else super(patterns, **options)
      end
    end

    def initialize(patterns, operator: :|, **options)
      @operator = operator.to_sym
      @patterns = patterns.flat_map { |p| patterns_from(p, **options) }
    end

    # @see Mustermann::Pattern#names
    def names
      @names ||= Mustermann.dedup(patterns.flat_map { |p| p.respond_to?(:names) ? p.names : [] }.uniq)
    end

    # @see Mustermann::Pattern#==
    def ==(pattern)
      patterns == patterns_from(pattern)
    end

    # @see Mustermann::Pattern#eql?
    def eql?(pattern)
      patterns.eql? patterns_from(pattern)
    end

    # @see Mustermann::Pattern#hash
    def hash
      patterns.hash | operator.hash
    end

    # @see Mustermann::Pattern#===
    def ===(string)
      patterns.map { |p| p === string }.inject(operator)
    end

    # @see Mustermann::Pattern#params
    def params(string)
      with_matching(string, :params)
    end

    # @see Mustermann::Pattern#match
    def match(string)
      with_matching(string, :match)
    end

    # @!visibility private
    def respond_to_special?(method)
      return false unless operator == :|
      patterns.all? { |p| p.respond_to?(method) }
    end

    # (see Mustermann::Pattern#expand)
    def expand(behavior = nil, values = {})
      raise NotImplementedError, 'expanding not supported' unless respond_to? :expand
      @expander ||= Mustermann::Expander.new(*patterns)
      @expander.expand(behavior, values)
    end

    # (see Mustermann::Pattern#to_templates)
    def to_templates
      raise NotImplementedError, 'template generation not supported' unless respond_to? :to_templates
      patterns.flat_map(&:to_templates).uniq
    end

    # @return [String] the string representation of the pattern
    def to_s = inspect

    # @!visibility private
    def inspect
      "(#{simple_inspect})"
    end

    # @!visibility private
    def simple_inspect
      patterns.map { |p| p.is_a?(Composite) ? p.inspect : p.simple_inspect }.join(" #{operator} ")
    end

    # @!visibility private
    def pretty_print(q)
      q.group(1, "(", ")") do
        patterns.each_with_index do |pattern, index|
          unless index == 0
            q.text " #{operator}"
            q.breakable " "
          end
          if pattern.is_a?(Composite)
            q.pp pattern
          else
            q.text pattern.simple_inspect
          end
        end
      end
    end

    # @!visibility private
    def with_matching(string, method)
      return unless self === string
      pattern = patterns.detect { |p| p === string }
      pattern.public_send(method, string) if pattern
    end

    # @!visibility private
    def patterns_from(pattern, **options)
      return pattern.patterns if pattern.is_a? Composite and pattern.operator == self.operator
      [options.empty? && pattern.is_a?(Pattern) ? pattern : Mustermann.new(pattern, **options)]
    end

    private :with_matching, :patterns_from
  end
end
