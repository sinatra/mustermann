# frozen_string_literal: true
require 'strscan'

module Mustermann
  module Visualizer
    # @!visibility private
    module Highlighter
      # Provides highlighting for {Mustermann::Regular}
      # @!visibility private
      class Regular
        # @!visibility private
        SPECIAL_ESCAPE = ['w', 'W', 'd', 'D', 'h', 'H', 's', 'S', 'G', 'b', 'B']
        private_constant(:SPECIAL_ESCAPE)

        # @!visibility private
        def self.highlight?(pattern)
          pattern.class.name == "Mustermann::Regular"
        end

        # @!visibility private
        def self.highlight(pattern, renderer)
          new(renderer).highlight(pattern)
        end

        # @!visibility private
        attr_reader :renderer, :output, :scanner

        # @!visibility private
        def initialize(renderer)
          @renderer = renderer
          @output   = String.new
        end

        # @!visibility private
        def highlight(pattern)
          output << renderer.pre(:root)
          @scanner = ::StringScanner.new(pattern.to_s)
          scan
          output << renderer.post(:root)
        end

        # @!visibility private
        def scan(stop = nil)
          until scanner.eos?
            case char = scanner.getch
            when stop                then return char
            when ?/                  then element(:separator, char)
            when Regexp.escape(char) then element(:char, char)
            when ?\\                 then escaped(scanner.getch)
            when ?(                  then potential_capture
            when ?[                  then char_class
            when ?^, ?$              then element(:illegal, char)
            when ?{                  then element(:special, "\{#{scanner.scan(/[^\}]*\}/)}")
            else element(:special, char)
            end
          end
        end

        # @!visibility private
        def char_class
          if result = scanner.scan(/\[:\w+:\]\]/)
            element(:special, "[#{result}")
          else
            element(:special, ?[)
            element(:special, ?^) if scanner.scan(/\^/)
          end
        end

        # @!visibility private
        def potential_capture
          if scanner.scan(/\?<(\w+)>/)
            element(:capture, "(?<") do
              element(:name, scanner[1])
              output << ">" << scan(?))
            end
          elsif scanner.scan(/\?(?:(?:-\w+)?:|>|<=|<!|!|=)/)
            element(:special, "(#{scanner[0]}")
          else
            element(:capture, "(") { output << scan(?)) }
          end
        end

        # @!visibility private
        def escaped(char)
          case char
          when  *SPECIAL_ESCAPE    then element(:special, "\\#{char}")
          when 'A', 'Z', 'z'       then element(:illegal, "\\#{char}")
          when 'g'                 then element(:special, "\\#{char}#{scanner.scan(/<\w*>/)}")
          when 'p', 'u'            then element(:special, "\\#{char}#{scanner.scan(/\{[^\}]*\}/)}")
          when ?/                  then element(:separator, char)
          else element(:escaped, ?\\) { element(:escaped_char, char) }
          end
        end

        # @!visibility private
        def element(type, content = nil)
          output << renderer.pre(type)
          output << renderer.escape(content) if content
          yield if block_given?
          output << renderer.post(type)
        end
      end
    end
  end
end
