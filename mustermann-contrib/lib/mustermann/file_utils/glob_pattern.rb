# frozen_string_literal: true
require 'mustermann/ast/translator'

module Mustermann
  module FileUtils
    # AST Translator to turn Mustermann patterns into glob patterns.
    # @!visibility private
    class GlobPattern < Mustermann::AST::Translator
      # Character that need to be escaped in glob patterns.
      # @!visibility private
      ESCAPE = %w([ ] { } * ** \\)

      # Turn a Mustermann pattern into glob pattern.
      # @param [#to_glob, #to_ast, Object] pattern the object to turn into a glob pattern.
      # @return [String] the glob pattern
      # @!visibility private
      def self.generate(pattern)
        return pattern.to_glob               if pattern.respond_to? :to_glob
        return new.translate(pattern.to_ast) if pattern.respond_to? :to_ast
        return "**/*" unless pattern.is_a? Mustermann::Composite
        "{#{pattern.patterns.map { |p| generate(p) }.join(',')}}"
      end

      translate(:root, :group, :expression) { t(payload) || ""                           }
      translate(:separator, :char)          { t.escape(payload)                          }
      translate(:capture)                   { constraint ? "**/*" : "*"                  }
      translate(:optional)                  { "{#{t(payload)},}"                         }
      translate(:named_splat, :splat)       { "**/*"                                     }
      translate(:with_look_ahead)           { t(head) + t(payload)                       }
      translate(:union)                     { "{#{payload.map { |e| t(e) }.join(',')}}"  }
      translate(Array)                      { map { |e| t(e) }.join                      }

      # Escape with a slash rather than URI escaping.
      # @!visibility private
      def escape(char)
        ESCAPE.include?(char) ? "\\#{char}" : char
      end
    end
  end
end
