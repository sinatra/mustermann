# Implementing Custom Patterns

Mustermann ships with many built-in pattern types — Sinatra, Rails, URI templates, and more. But sometimes none of them fit your needs. This guide walks you through building your own pattern type, starting from the simplest possible approach and working up to a full AST-based implementation.

## The Simplest Case: Subclassing `Mustermann::Pattern`

Every pattern in Mustermann ultimately inherits from `Mustermann::Pattern`. The only method you _must_ override is `===`, which determines whether a string matches your pattern.

```ruby
require 'mustermann/pattern'

class WikiPattern < Mustermann::Pattern
  register :wiki

  def ===(string)
    # A wiki pattern is just a literal path where spaces are allowed.
    # Match after normalizing spaces.
    unescape(string).gsub('_', ' ') == @string.gsub('_', ' ')
  end
end
```

The `register` call makes your pattern available through `Mustermann.new`:

```ruby
pattern = Mustermann.new('hello world', type: :wiki)
pattern === 'hello_world'  # => true
pattern === 'hello world'  # => true
pattern === 'hello-world'  # => false
```

The `unescape` method is provided by the base class. It URI-decodes the input string when the `:uri_decode` option is true (the default).

### What you get for free

Even with just `===` implemented, the base class provides several useful methods:

```ruby
pattern.match('hello_world')   # => #<Mustermann::Match>
pattern.params('hello_world')  # => {} (empty, no captures yet)
pattern =~ 'hello_world'       # => 0
pattern.peek('hello_world/more') # => "hello_world"
```

`match`, `=~`, and `peek` all delegate to `===` under the hood.

### Declaring supported options

If your pattern type accepts custom options, declare them with `supported_options`:

```ruby
class WikiPattern < Mustermann::Pattern
  register :wiki
  supported_options :case_sensitive

  def initialize(string, case_sensitive: true, **options)
    super(string, **options)
    @case_sensitive = case_sensitive
  end

  def ===(string)
    normalized_input   = unescape(string).gsub('_', ' ')
    normalized_pattern = @string.gsub('_', ' ')
    return normalized_input == normalized_pattern if @case_sensitive
    normalized_input.downcase == normalized_pattern.downcase
  end
end
```

Mustermann raises an `ArgumentError` if an option is passed that is not declared, so this keeps the API clean.

## Adding Parameter Extraction: Subclassing `Mustermann::RegexpBased`

If you want your pattern to extract named parameters from a match (like `:name` does in Sinatra patterns), the easiest path is to compile your pattern to a regular expression.

`Mustermann::RegexpBased` handles all the matching and param extraction for you. You only need to implement one method: `compile`, which returns a `Regexp` without anchors (the base class adds `\A` and `\Z` automatically).

```ruby
require 'mustermann/regexp_based'

class ColonPattern < Mustermann::RegexpBased
  register :colon

  private

  def compile(**options)
    # Turn ":name" segments into named capture groups.
    regexp_string = Regexp.escape(@string).gsub(/\\:(\w+)/) do
      "(?<#{$1}>[^/]+)"
    end
    Regexp.new(regexp_string)
  end
end
```

```ruby
pattern = Mustermann.new('/:name/:ext', type: :colon)
pattern === '/hello/rb'          # => true
pattern.params('/hello/rb')      # => {"name" => "hello", "ext" => "rb"}
pattern.match('/hello/rb')[:name] # => "hello"
```

Named capture groups in the compiled regexp become entries in the params hash. The base class calls `map_param(key, value)` on each capture before returning it, which applies URI decoding by default.

### Exposing capture names

Because `RegexpBased` delegates `names` to the underlying regexp, you get named capture introspection for free:

```ruby
pattern.names  # => ["name", "ext"]
```

## The Full System: Subclassing `Mustermann::AST::Pattern`

For richer pattern syntaxes — optional segments, splats, inline constraints, union alternations — you want to work at the AST level. `Mustermann::AST::Pattern` parses your pattern string into a tree of nodes, then compiles that tree to a regexp. You define the grammar by telling the parser what to do with each special character.

### How it fits together

```
Pattern string  →  Parser  →  AST  →  Compiler  →  Regexp
```

The Parser walks the string character by character. When it encounters a character you have registered, it calls your block and expects an AST node back. The Compiler then visits each node and produces a regexp fragment.

### Defining grammar rules with `on`

Inside a `Parser` subclass, you use `on` to register handlers for specific characters:

```ruby
require 'mustermann/ast/pattern'

class HashPattern < Mustermann::AST::Pattern
  register :hash

  class Parser < Mustermann::AST::Parser
    # "#name" captures a segment
    on(?#) { |char| node(:capture) { scan(/\w+/) } }

    # "**" is a splat (matches anything, including slashes)
    on(?*) { |char| scan("*") ? node(:splat) : node(:char, char) }
  end
end
```

```ruby
pattern = Mustermann.new('/#name/**', type: :hash)
pattern === '/alice/photos/2024'  # => true
pattern.params('/alice/photos/2024')
# => {"name" => "alice", "splat" => ["photos/2024"]}
```

The `on` method takes one or more characters (or `nil` for end-of-string) and a block. When the parser reads that character, it calls your block with the character and uses the return value as the next node.

You can also register the same handler for multiple characters at once:

```ruby
on(?!, ?@) { |char| unexpected(char) }
```

### Node types

The built-in node types cover the common cases. Here is a quick reference:

| Node | Purpose | Example use |
|------|---------|-------------|
| `:char` | A literal character | `node(:char, 'x')` |
| `:separator` | A path separator (`/`) | `node(:separator, '/')` |
| `:capture` | A named parameter capture | `node(:capture) { scan(/\w+/) }` |
| `:splat` | An unnamed wildcard (`splat` key in params) | `node(:splat)` |
| `:named_splat` | A named wildcard | `node(:named_splat, 'rest')` |
| `:group` | A grouped sequence | `node(:group) { ... }` |
| `:optional` | A group that may be absent | `node(:optional, inner_node)` |
| `:union` | Two or more alternatives | `node(:union, [a, b])` |
| `:or` | Separator between union arms | `node(:or)` |

You look up a node class by symbol with `Node[type]`, but in practice you rarely need to do this directly — the `node` helper in the parser does it for you.

### The `node` helper

The `node` method creates a node and records its position in the source string:

```ruby
node(type, *args, &block)
```

- `type` is a symbol naming the node class (e.g., `:capture`, `:splat`).
- `args` become the node's payload.
- When a block is given, the parser calls `parse` on the new node, which repeatedly calls `yield` (your block) and appends the results to the node's payload.

```ruby
on(?:) { |char| node(:capture) { scan(/\w+/) } }
```

This reads a `:` character, then reads word characters into a `:capture` node's payload (the capture name). The block passed to `node` is invoked by the node's own `parse` method, which keeps calling `yield` until it returns `nil` and collects the results.

```ruby
on(?() { |char| node(:group) { read unless scan(?)) } }
```

This reads a `(`, then keeps reading nodes until it finds a matching `)`. Each call to `read` parses one node from the buffer and adds it to the group's payload.

### Reading from the buffer

Inside the `on` block, several helpers let you consume input:

```ruby
scan(regexp)       # Match regexp at current position, advance buffer. Returns the match or nil.
expect(regexp)     # Like scan, but raises ParseError if nothing matches.
unexpected(char)   # Raise a ParseError about an unexpected character.
```

`scan` returns a `String` for simple regexps. If the regexp contains named captures, it returns a `MatchData` instead:

```ruby
on(?<) do |char|
  match = expect(/(?<name>\w+)>/)
  node(:capture, match[:name])
end
```

### A working example: angle-bracket captures

Here is a complete custom pattern type that uses `<name>` syntax for captures:

```ruby
require 'mustermann/ast/pattern'

class AnglePattern < Mustermann::AST::Pattern
  register :angle

  class Parser < Mustermann::AST::Parser
    # Disallow unmatched > at the top level
    on(?>) { |char| unexpected(char) }

    on(?<) do |char|
      name = expect(/\w+/)
      expect(?>)
      node(:capture, name)
    end

    # "**" becomes a greedy splat
    on(?*) do |char|
      if scan(?*)
        node(:named_splat, 'path')
      else
        name = scan(/\w+/)
        name ? node(:named_splat, name) : node(:splat)
      end
    end
  end
end
```

```ruby
pattern = Mustermann.new('/users/<id>/posts/<slug>', type: :angle)
pattern === '/users/42/posts/hello-world'   # => true
pattern.params('/users/42/posts/hello-world')
# => {"id" => "42", "slug" => "hello-world"}

pattern = Mustermann.new('/files/**', type: :angle)
pattern.params('/files/img/logo.png')
# => {"path" => ["img/logo.png"]}
```

### Using `suffix` for postfix modifiers

Sometimes you want a character that follows a node to modify it — the classic example is `?` making the preceding group optional. The `suffix` method registers a handler that fires after a node is created:

```ruby
suffix(??, after: :capture) do |match, element|
  node(:optional, element)
end
```

The block receives the matched suffix and the node it follows, and should return the replacement node.

The `after:` option restricts which node types the suffix can follow. Using `:node` (or omitting `after:`) applies the suffix after any node. Using a more specific type like `:capture` or `:group` keeps the grammar from applying the suffix in unexpected places.

Here is the angle-bracket pattern extended with optional captures:

```ruby
class Parser < Mustermann::AST::Parser
  on(?>) { |char| unexpected(char) }

  on(?<) do |char|
    name = expect(/\w+/)
    expect(?>)
    node(:capture, name)
  end

  # Make any capture optional when followed by ?
  suffix(??, after: :capture) do |match, element|
    node(:optional, element)
  end
end
```

```ruby
pattern = Mustermann.new('/posts/<year>/<slug>?', type: :angle)
pattern.params('/posts/2024/hello')  # => {"year" => "2024", "slug" => "hello"}
pattern.params('/posts/2024')        # => {"year" => "2024", "slug" => nil}
```

### Capture constraints

A `:capture` node can carry a `constraint` attribute to restrict what it matches. This is a raw regexp fragment (without the named capture wrapper):

```ruby
on(?<) do |char|
  match = expect(/(?<name>\w+)/)
  constraint = scan(/:\w+/)  # optional ":type" annotation
  expect(?>)
  n = node(:capture, match[:name])
  n.constraint = '\d+' if constraint == ':int'
  n
end
```

```ruby
pattern = Mustermann.new('/items/<id:int>', type: :angle)
pattern === '/items/42'    # => true
pattern === '/items/foo'   # => false
```

### Handling unknown characters

By default, unrecognized characters become `:char` nodes (literal matches) or `:separator` nodes for `/`. If you want to forbid certain characters, register them with `unexpected`:

```ruby
on(?[, ?], ?{, ?}) { |char| unexpected(char) }
```

This raises a `Mustermann::ParseError` with a clear message when those characters appear in a pattern.

## Registering your pattern

Call `register` on your class with one or more symbols to make them available through `Mustermann.new`:

```ruby
class AnglePattern < Mustermann::AST::Pattern
  register :angle
end

Mustermann.new('/users/<id>', type: :angle)
```

You can register multiple names for the same class:

```ruby
register :angle, :angle_bracket
```

## Putting it all together

Here is a self-contained example combining everything above — a pattern type with custom captures, splats, optional segments, and a constraint syntax:

```ruby
require 'mustermann/ast/pattern'

class BracePattern < Mustermann::AST::Pattern
  register :brace

  class Parser < Mustermann::AST::Parser
    # Disallow unmatched closing braces
    on(?}) { |char| unexpected(char) }

    # {name} for a capture, {+name} for a named splat
    on(?{) do |char|
      if scan(?+)
        name = expect(/\w+/)
        expect(?})
        node(:named_splat, name)
      else
        name = expect(/\w+/)
        constraint = scan(/:\w+/)
        expect(?})
        n = node(:capture, name)
        n.constraint = '\d+' if constraint == ':int'
        n.constraint = '\w+' if constraint == ':word'
        n
      end
    end

    # Groups with (...)
    on(?() { |char| node(:group) { read unless scan(?)) } }

    # Alternation with |
    on(?|) { |char| node(:or) }

    # Make captures and groups optional with ?
    suffix(??, after: :capture) { |m, e| node(:optional, e) }
    suffix(??, after: :group)   { |m, e| node(:optional, e) }
  end
end
```

```ruby
p = Mustermann.new('/users/{id:int}/posts/{slug}?', type: :brace)

p === '/users/42/posts/hello'  # => true
p === '/users/42/posts'        # => true
p === '/users/foo/posts'       # => false

p.params('/users/42/posts/hello')
# => {"id" => "42", "slug" => "hello"}

p.params('/users/42/posts')
# => {"id" => "42", "slug" => nil}

p = Mustermann.new('/files/{+rest}', type: :brace)
p.params('/files/img/logo.png')
# => {"rest" => ["img/logo.png"]}
```

Because `BracePattern` inherits from `Mustermann::AST::Pattern`, it also gets `expand` and `to_templates` support automatically, along with all the standard `Pattern` methods like `peek`, `match`, and composition operators.
