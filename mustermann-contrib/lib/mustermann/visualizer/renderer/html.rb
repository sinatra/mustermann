# frozen_string_literal: true
require 'mustermann/visualizer/renderer/generic'
require 'cgi'

module Mustermann
  module Visualizer
    # @!visibility private
    module Renderer
      # Generates HTML output.
      # @!visibility private
      class HTML < Generic
        # @!visibility private
        def initialize(target, tag: :span, class_prefix: "mustermann_", css: :inline, **options)
          raise ArgumentError, 'css option %p not supported, should be true, false or inline' if css != true and css != false and css != :inline
          super(target, **options)
          @css, @tag, @class_prefix = css, tag, class_prefix
        end

        # @!visibility private
        def preamble
          "<style type=\"text/css\">\n%s</style>" %  stylesheet if  @css == true
        end

        # @!visibility private
        def stylesheet
          @target.theme.to_css { |name| ".#{@class_prefix}pattern .#{@class_prefix}#{name}" }
        end

        # @!visibility private
        def escape_string(string)
          CGI.escape_html(string)
        end

        # @!visibility private
        def pre(type)
          if @css == :inline
            return "" unless rule = @target.theme[type]
            "<#{@tag} style=\"#{rule.to_css_rule}\">"
          else
            "<#{@tag} class=\"#{@class_prefix}#{type}\">"
          end
        end

        # @!visibility private
        def post(type)
          "</#{@tag}>"
        end
      end
    end
  end
end
