require 'mustermann/ast/translator'
require 'mustermann/ast/compiler'

module Mustermann
  module AST
    class Expander < Translator
      raises ExpandError

      translate Array do
        inject(t.pattern) do |pattern, element|
          t.add_to(pattern, t(element))
        end
      end

      translate :capture do
        t.for_capture(node)
      end

      translate :named_splat, :splat do
        t.pattern + t.for_capture(node)
      end

      translate :root, :group, :expression do
        t(payload)
      end

      translate :char do
        t.pattern(t.escape(payload, also_escape: /[\/\?#\&\=%]/).gsub(?%, "%%"))
      end

      translate :separator do
        t.pattern(payload.gsub(?%, "%%"))
      end

      translate :with_look_ahead do
        t.add_to(t(head), t(payload))
      end

      translate :optional do
        nested = t(payload)
        nested += t.pattern unless nested.any? { |n| n.first.empty? }
        nested
      end

      def for_capture(node)
        name = node.name.to_sym
        pattern('%s', name, name => /(?!#{pattern_for(node)})./)
      end

      def mappings
        @mappings ||= {}
      end

      def add(ast)
        translate(ast).each do |keys, pattern, filter|
          mappings[keys.uniq.sort] ||= [keys, pattern, filter]
        end
      end

      def pattern_for(node, **options)
        Compiler.new.decorator_for(node).pattern(**options)
      end

      def expand(**values)
        keys, pattern, filters = mappings.fetch(values.keys.sort) { error_for(values) }
        filters.each { |key, filter| values[key] &&= escape(values[key], also_escape: filter) }
        pattern % values.values_at(*keys)
      end

      def error_for(values)
        expansions = mappings.keys.map(&:inspect).join(" or ")
        raise error_class, "cannot expand with keys %p, possible expansions: %s" % [values.keys.sort, expansions]
      end

      def escape(string, *args)
        # URI::Parser is pretty slow, let's not had every string to it, even if it's uneccessary
        string =~ /\A\w*\Z/ ? string : super
      end

      def pattern(string = "", *keys, **filters)
        [[keys, string, filters]]
      end

      def add_to(list, result)
        list << [[], ""] if list.empty?
        list.inject([]) { |l, (k1, p1, f1)| l + result.map { |k2, p2, f2| [k1+k2, p1+p2, **f1, **f2] } }
      end
    end
  end
end
