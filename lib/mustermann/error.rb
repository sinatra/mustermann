module Mustermann
  # Raised if anything goes wrong while generating a {Pattern}.
  class Error < StandardError; end

  # Raised if anything goes wrong while compiling a {Pattern}.
  class CompileError < Error; end

  # Raised if anything goes wrong while parsing a {Pattern}.
  class ParseError < Error; end
end