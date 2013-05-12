# Internal API

This document describes how to use [Mustermann](README.md)'s internal API.

It is a secondary goal to keep the internal API as stable as possible, in a state where it would well be possible to interface with it.
However, the internal API is not covered by Semantic Versioning. As a rule of thumb, no backwards incompatible changes should be introduced to the API in minor releases (starting from 1.0.0).

Should the internal API gain widespread/production use, we might consider moving parts of it over into the public API.

Here is a quick example of what you can do with this:

``` ruby
require 'mustermann/ast/pattern'

class MyPattern < Mustermann::AST::Pattern
  on("~") { |c| node(:capture,     buffer[1]) if expect(/\{(\w+)\}/) }
  on("+") { |c| node(:named_splat, buffer[1]) if expect(/\{(\w+)\}/) }
  on("?") { |c| node(:optional, node(:capture, buffer[1])) if expect(/\{(\w+)\}/) }
end

pattern = MyPattern.new("/+{prefix}/~{page}/?{optional}")
pattern.params("/a/")     # => nil
pattern.params("/a/b/")   # => { "prefix" => "a",   "page" => "b", "optional" => nil }
pattern.params("/a/b/c")  # => { "prefix" => "a",   "page" => "b", "optional" => "c" }
pattern.params("/a/b/c/") # => { "prefix" => "a/b", "page" => "c", "optional" => nil }

pattern.expand(prefix: "a",   page: "foo") # => "/a/foo/"
pattern.expand(prefix: "a/b", page: "c/d") # => "/a/b/c%2Fd/"

require 'mustermann'
Mustermann.register(:my_pattern, MyPattern, load: false)
Mustermann.new('/+{prefix}/~{page}/?{optional}', type: :my_pattern) # => #<MyPattern:"/+{prefix}/~{page}/?{optional}">

require 'sinatra/base'
class MyApp < Sinatra::Base
  register Mustermann
  set :pattern, type: :my_pattern

  get '/hello/~{name}' do
    "Hello #{params[:name].capitalize}!"
  end
end

require 'mustermann/ast/tree_renderer'
ast = MyPattern::Parser.parse(pattern.to_s)
puts Mustermann::AST::TreeRenderer.render(ast)

```

## Pattern Registration

...

## Build Your Own Pattern

...

## Patterns Based on Regular Expressions

...

## AST-Based Patterns

...