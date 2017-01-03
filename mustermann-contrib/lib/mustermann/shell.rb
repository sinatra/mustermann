# frozen_string_literal: true
require 'mustermann'
require 'mustermann/pattern'
require 'mustermann/simple_match'

module Mustermann
  # Matches strings that are identical to the pattern.
  #
  # @example
  #   Mustermann.new('/*.*', type: :shell) === '/bar' # => false
  #
  # @see Mustermann::Pattern
  # @see file:README.md#shell Syntax description in the README
  class Shell < Pattern
    include Concat::Native
    register :shell

    # @!visibility private
    # @return [#highlight, nil]
    #   highlighing logic for mustermann-visualizer,
    #   nil if mustermann-visualizer hasn't been loaded
    def highlighter
      return unless defined? Mustermann::Visualizer::Highlighter
      @@highlighter ||= Mustermann::Visualizer::Highlighter.create do
        on('\\') { |matched| escaped(matched, scanner.getch) }
        on(/[\*\[\]]/, :special)
        on("{") { nested(:union, ?{, ?}, ?,) }
      end
    end

    # @param (see Mustermann::Pattern#initialize)
    # @return (see Mustermann::Pattern#initialize)
    # @see (see Mustermann::Pattern#initialize)
    def initialize(string, **options)
      @flags = File::FNM_PATHNAME | File::FNM_DOTMATCH | File::FNM_EXTGLOB
      super(string, **options)
    end

    # @param (see Mustermann::Pattern#===)
    # @return (see Mustermann::Pattern#===)
    # @see (see Mustermann::Pattern#===)
    def ===(string)
      File.fnmatch? @string, unescape(string), @flags
    end

    # @param (see Mustermann::Pattern#peek_size)
    # @return (see Mustermann::Pattern#peek_size)
    # @see (see Mustermann::Pattern#peek_size)
    def peek_size(string)
      @peek_string ||= @string + "{**,/**,/**/*}"
      super if File.fnmatch? @peek_string, unescape(string), @flags
    end

    # Used by {Mustermann::FileUtils} to not use a generic glob pattern.
    alias_method :to_glob, :to_s
  end
end
