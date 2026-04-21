# The Amazing Mustermann

*Make sure you view the correct docs: [latest release](https://rubydoc.info/gems/mustermann/), [master](http://rubydoc.info/github/sinatra/mustermann).*

Welcome to [Mustermann](http://en.wikipedia.org/wiki/List_of_placeholder_names_by_language#German). Mustermann is your personal string matching expert. As an expert in the field of strings and patterns, Mustermann keeps its runtime dependencies to a minimum and is fully covered with specs and documentation.

Given a string pattern, Mustermann will turn it into an object that behaves like a regular expression and has comparable performance characteristics.

``` ruby
if '/foo/bar' =~ Mustermann.new('/foo/*')
  puts 'it works!'
end

case 'something.png'
when Mustermann.new('foo/*') then puts "prefixed with foo"
when Mustermann.new('*.pdf') then puts "it's a PDF"
when Mustermann.new('*.png') then puts "it's an image"
end

pattern = Mustermann.new('/:prefix/*.*')
pattern.params('/a/b.c') # => { "prefix" => "a", splat => ["b", "c"] }
```

## Overview

### Features

* **[Pattern Types](#-pattern-types):** Mustermann supports a wide variety of different pattern types, making it compatible with a large variety of existing software.
* **[Fine Grained Control](#-available-options):** You can easily adjust matching behavior and add constraints to the placeholders and capture groups.
* **[Binary Operators](#-binary-operators) and [Concatenation](#-concatenation):** Patterns can be combined into composite patterns using binary operators.
* **[Regexp Look Alike](#-regexp-look-alike):** Mustermann patterns can be used as a replacement for regular expressions.
* **[Parameter Parsing](#-parameter-parsing):** Mustermann can parse matched parameters into a Sinatra-style "params" hash, including type casting.
* **[Peeking](#-peeking):** Lets you check if the beginning of a string matches a pattern.
* **[Expanding](#-expanding):** Besides parsing a parameters from an input string, a pattern object can also be used to generate a string from a set of parameters.
* **[Generating Templates](#-generating-templates):** This comes in handy when wanting to hand on patterns rather than fully expanded strings as part of an external API.
* **[Proc Look Alike](#-proc-look-alike):** Pass on a pattern instead of a block.
* **[Duck Typing](#-duck-typing):** You can create your own pattern-like objects by implementing `to_pattern`.
* **[Performance](#-performance):** Patterns are implemented with both performance and a low memory footprint in mind.

### Additional Tooling

These features are included in the library, but not loaded by default

* **[Pattern Set](#-pattern-set):** A collection of patterns with associated values, designed for building routing tables that dispatch efficiently as the number of routes grows.
* **Mustermann::Router:** A very basic rack router built on top of `Mustermann::Set` for demonstration purposes. Simple and fast.

<a name="-pattern-types"></a>
## Pattern Types

Mustermann support multiple pattern types. A pattern type defines the syntax, matching semantics and whether certain features, like [expanding](#-expanding) and [generating templates](#-generating-templates), are available.

You can create a pattern of a certain type by passing `type` option to `Mustermann.new`:

``` ruby
require 'mustermann'
pattern = Mustermann.new('/*/**', type: :shell)
```

Note that this will use the type as suggestion: When passing in a string argument, it will create a pattern of the given type, but it might choose a different type for other objects (a regular expression argument will always result in a [regexp](../docs/patterns/regexp.md) pattern, a symbol always in a [sinatra](../docs/patterns/sinatra.md) pattern, etc).

Alternatively, you can also load and instantiate the pattern type directly:

``` ruby
require 'mustermann/shell'
pattern = Mustermann::Shell.new('/*/**')
```

Mustermann itself includes the [sinatra](../docs/patterns/sinatra.md), [identity](../docs/patterns/identity.md) and [regexp](../docs/patterns/regexp.md) pattern types. Other pattern types are available as separate gems.

<a name="-binary-operators"></a>
## Binary Operators

Patterns can be combined via binary operators. These are:

* `|` (or):  Resulting pattern matches if at least one of the input pattern matches.
* `&` (and): Resulting pattern matches if all input patterns match.
* `^` (xor): Resulting pattern matches if exactly one of the input pattern matches.

``` ruby
require 'mustermann'

first  = Mustermann.new('/foo/:input')
second = Mustermann.new('/:input/bar')

first | second === "/foo/foo" # => true
first | second === "/foo/bar" # => true

first & second === "/foo/foo" # => false
first & second === "/foo/bar" # => true

first ^ second === "/foo/foo" # => true
first ^ second === "/foo/bar" # => false
```

These resulting objects are fully functional pattern objects, allowing you to call methods like `params` or `to_proc` on them. Moreover, *or* patterns created solely from expandable patterns will also be expandable. The same logic also applies to generating templates from *or* patterns.

<a name="-concatenation"></a>
## Concatenation

Similar to [Binary Operators](#-binary-operators), two patterns can be concatenated using `+`.

``` ruby
require 'mustermann'

prefix = Mustermann.new("/:prefix")
about  = prefix + "/about"

about.params("/main/about") # => {"prefix" => "main"}
```

Patterns of different types can be mixed. The availability of `to_templates` and `expand` depends on the patterns being concatenated.

<a name="-regexp-look-alike"></a>
## Regexp Look Alike

Pattern objects mimic Ruby's `Regexp` class by implementing `match`, `=~`, `===`, `names` and `named_captures`.

``` ruby
require 'mustermann'

pattern = Mustermann.new('/:page')
pattern.match('/')     # => nil
pattern.match('/home') # => #<MatchData "/home" page:"home">
pattern =~ '/home'     # => 0
pattern === '/home'    # => true (this allows using it in case statements)

pattern = Mustermann.new('/home', type: :identity)
pattern.match('/')     # => nil
pattern.match('/home') # => #<Mustermann::Match ...>
pattern =~ '/home'     # => 0
pattern === '/home'    # => true (this allows using it in case statements)
```

Moreover, patterns based on regular expressions (all but `identity` and `shell`) automatically convert to regular expressions when needed:

``` ruby
require 'mustermann'

pattern = Mustermann.new('/:page')
union   = Regexp.union(pattern, /^$/)

union =~ "/foo" # => 0
union =~ ""     # => 0

Regexp.try_convert(pattern) # => /.../
```

This way, unless some code explicitly checks the class for a regular expression, you should be able to pass in a pattern object instead even if the code in question was not written with Mustermann in mind.

<a name="-parameter-parsing"></a>
## Parameter Parsing

Besides being a `Regexp` look-alike, Mustermann also adds a `params` method, that will give you a Sinatra-style hash:

``` ruby
require 'mustermann'

pattern = Mustermann.new('/:prefix/*.*')
pattern.params('/a/b.c') # => { "prefix" => "a", splat => ["b", "c"] }
```

For patterns with typed captures, it will also automatically convert them:

``` ruby
require 'mustermann'

pattern = Mustermann.new('/<prefix>/<int:id>', type: :flask)
pattern.params('/page/10') # => { "prefix" => "page", "id" => 10 }
```

<a name="-peeking"></a>
## Peeking

Peeking gives the option to match a pattern against the beginning of a string rather the full string. Patterns come with four methods for peeking:

* `peek` returns the matching substring.
* `peek_size` returns the number of characters matching.
* `peek_match` will return a `Mustermann::Match` (just like `match` does for the full string)
* `peek_params` will return the `params` hash parsed from the substring and the number of characters.

All of the above will turn `nil` if there was no match.

``` ruby
require 'mustermann'

pattern = Mustermann.new('/:prefix')
pattern.peek('/foo/bar')      # => '/foo'
pattern.peek_size('/foo/bar') # => 4

path_info    = '/foo/bar'
params, size = patter.peek_params(path_info)  # params == { "prefix" => "foo" }
rest         = path_info[size..-1]            # => "/bar"
```

<a name="-expanding"></a>
## Expanding

Similarly to parsing, it is also possible to generate a string from a pattern by expanding it with a hash.
For simple expansions, you can use `Pattern#expand`.

``` ruby
pattern = Mustermann.new('/:file(.:ext)?')
pattern.expand(file: 'pony')             # => "/pony"
pattern.expand(file: 'pony', ext: 'jpg') # => "/pony.jpg"
pattern.expand(ext: 'jpg')               # raises Mustermann::ExpandError
```

Expanding can be useful for instance when implementing link helpers.

### Expander Objects

To get fine-grained control over expansion, you can use `Mustermann::Expander` directly.

You can create an expander object directly from a string:

``` ruby
require 'mustermann/expander'
expander = Mustermann::Expander("/:file.jpg")
expander.expand(file: 'pony') # => "/pony.jpg"

expander = Mustermann::Expander(":file(.:ext)", type: :rails)
expander.expand(file: 'pony', ext: 'jpg') # => "/pony.jpg"
```

Or you can pass it a pattern instance:

``` ruby
require 'mustermann'
pattern = Mustermann.new("/:file")

require 'mustermann/expander'
expander = Mustermann::Expander.new(pattern)
```

### Expanding Multiple Patterns

You can add patterns to an expander object via `<<`:

``` ruby
require 'mustermann'

expander = Mustermann::Expander.new
expander << "/users/:user_id"
expander << "/pages/:page_id"

expander.expand(user_id: 15) # => "/users/15"
expander.expand(page_id: 58) # => "/pages/58"
```

You can set pattern options when creating the expander:

``` ruby
require 'mustermann'

expander = Mustermann::Expander.new(type: :template)
expander << "/users/{user_id}"
expander << "/pages/{page_id}"
```

Additionally, it is possible to combine patterns of different types:

``` ruby
require 'mustermann'

expander = Mustermann::Expander.new
expander << Mustermann.new("/users/{user_id}", type: :template)
expander << Mustermann.new("/pages/:page_id",  type: :rails)
```

### Handling Additional Values

The handling of additional values passed in to `expand` can be changed by setting the `additional_values` option:

``` ruby
require 'mustermann'

expander = Mustermann::Expander.new("/:slug", additional_values: :raise)
expander.expand(slug: "foo", value: "bar") # raises Mustermann::ExpandError

expander = Mustermann::Expander.new("/:slug", additional_values: :ignore)
expander.expand(slug: "foo", value: "bar") # => "/foo"

expander = Mustermann::Expander.new("/:slug", additional_values: :append)
expander.expand(slug: "foo", value: "bar") # => "/foo?value=bar"
```

It is also possible to pass this directly to the `expand` call:

``` ruby
require 'mustermann'

pattern = Mustermann.new('/:slug')
pattern.expand(:append, slug: "foo", value: "bar") # => "/foo?value=bar"
```

<a name="-generating-templates"></a>
## Generating Templates

You can generate a list of URI templates that correspond to a Mustermann pattern (it is a list rather than a single template, as most pattern types are significantly more expressive than URI templates).

This comes in quite handy since URI templates are not made for pattern matching. That way you can easily use a more precise template syntax and have it automatically generate hypermedia links for you.

Template generation is supported by almost all patterns (notable exceptions are `shell`, `regexp` and `simple` patterns).

``` ruby
require 'mustermann'

Mustermann.new("/:name").to_templates                   # => ["/{name}"]
Mustermann.new("/:foo(@:bar)?/*baz").to_templates       # => ["/{foo}@{bar}/{+baz}", "/{foo}/{+baz}"]
Mustermann.new("/{name}", type: :template).to_templates # => ["/{name}"]
```

Union Composite patterns (with the | operator) support template generation if all patterns they are composed of also support it.

``` ruby
require 'mustermann'

pattern  = Mustermann.new('/:name')
pattern |= Mustermann.new('/{name}', type: :template)
pattern |= Mustermann.new('/example/*nested')
pattern.to_templates # => ["/{name}", "/example/{+nested}"]
```

If accepting arbitrary patterns, you can and should use `respond_to?` to check feature availability.

``` ruby
if pattern.respond_to? :to_templates
  pattern.to_templates
else
  warn "does not support template generation"
end
```

<a name="-proc-look-alike"></a>
## Proc Look Alike

Patterns implement `to_proc`:

``` ruby
require 'mustermann'
pattern  = Mustermann.new('/foo')
callback = pattern.to_proc # => #<Proc>

callback.call('/foo') # => true
callback.call('/bar') # => false
```

They can therefore be easily passed to methods expecting a block:

``` ruby
require 'mustermann'

list    = ["foo", "example@email.com", "bar"]
pattern = Mustermann.new(":name@:domain.:tld")
email   = list.detect(&pattern) # => "example@email.com"
```

<a name="-pattern-set"></a>
## Pattern Set

`Mustermann::Set` is a collection of patterns where each pattern is associated with an arbitrary value — typically a handler or action. A single call to `match` returns both the captured parameters and the value for the first matching pattern, making it straightforward to build a routing table.

``` ruby
require 'mustermann/set'

set = Mustermann::Set.new
set.add('/users/:id',  :users_show)
set.add('/posts/:id',  :posts_show)
set.add('/posts',      :posts_index)

m = set.match('/users/42')
m.value         # => :users_show
m.params['id']  # => '42'

set.match('/unknown')  # => nil
```

You can supply the initial mapping directly to the constructor:

``` ruby
set = Mustermann::Set.new(
  '/users/:id' => :users_show,
  '/posts/:id' => :posts_show
)
```

Or use a block for imperative setup:

``` ruby
set = Mustermann::Set.new do |s|
  s.add('/users/:id', :users_show)
  s.add('/posts/:id', :posts_show)
end
```

Pattern options such as `type:` are passed as keyword arguments and apply to all patterns in the set:

``` ruby
set = Mustermann::Set.new(type: :rails)
set.add('/:controller(/:action(/:id))', :route)
```

### Values

Each pattern can be associated with multiple values. `match` returns the first, while `match_all` returns one match per value:

``` ruby
set = Mustermann::Set.new
set.add('/users/:id', :admin_handler, :user_handler)

set.match('/users/1').value            # => :admin_handler
set.match_all('/users/1').map(&:value) # => [:admin_handler, :user_handler]
```

When no value is given, a match still succeeds but `value` is `nil`:

``` ruby
set = Mustermann::Set.new
set.add('/ping')
set.match('/ping').value  # => nil
```

### Peeking

`peek_match` matches a prefix of the input rather than the full string. The unmatched remainder is available via `post_match`:

``` ruby
set = Mustermann::Set.new
set.add('/users/:id', :users)

m = set.peek_match('/users/42/posts')
m.to_s        # => '/users/42'
m.post_match  # => '/posts'
m.value       # => :users
```

`peek_match_all` returns every pattern that matches a prefix:

``` ruby
results = set.peek_match_all('/users/42/posts')
results.map(&:value)      # => [:users]
results.map(&:post_match) # => ['/posts']
```

### Expanding

A set can generate strings from parameter hashes using the same interface as individual pattern expansion:

``` ruby
set = Mustermann::Set.new
set.add('/users/:id', :users)
set.add('/posts/:id', :posts)

set.expand(id: '5')          # => '/users/5'  (first applicable pattern)
set.expand(:posts, id: '5')  # => '/posts/5'  (patterns for a specific value)
```

### Match order

A set can match patterns and values in loose or strict insertion order.

You have the following guarantees without strict ordering:

* Patterns with dynamic segments in the same position and equal static parts will always match in the order they were added.
* Multiple values for the same pattern will retain their insertion order in regards to that pattern.

Trade-offs without strict ordering:

* Static segments may be favored over dynamic segments. If you want to guarantee this behavior, enable trie-mode proactively.
* When a pattern has multiple values, these will follow each other directly when using `match_all` or `peek_match_all`.

Strict ordering comes with both a performance overhead and marginally increased memory usage.
How big the performance overhead is depends on the number of patterns that overlap in the strings they successfully match against.
It does use Ruby's built-in sorting, which on MRI is based on quicksort. The memory overhead grows linear with the number
of pattern and value combinations, but is generally small compared to the memory used by the patterns and values themselves.

With strict ordering enabled, patterns and values are guaranteed to occur in insertion order.

Without strict ordering, not using a trie:

```ruby
set = Mustermann::Set.new(use_trie: false)

set.add("/:path",  :first)
set.add("/static", :second)
set.add("/:path",  :third)

set.match("/static").value             # => :first
set.match_all("/static").map(&:value)  # => [:first, :third, :second]
```

Without strict ordering, using a trie:

```ruby
set = Mustermann::Set.new(use_trie: true)

set.add("/:path",  :first)
set.add("/static", :second)
set.add("/:path",  :third)

set.match("/static").value             # => :second
set.match_all("/static").map(&:value)  # => [:second, :first, :third]
```

With strict ordering enabled, regardless of whether a trie is used or not:

```ruby
set = Mustermann::Set.new(strict_order: true)

set.add("/:path",  :first)
set.add("/static", :second)
set.add("/:path",  :third)

set.match("/static").value             # => :first
set.match_all("/static").map(&:value)  # => [:first, :second, :third]
```

<a name="-duck-typing"></a>
## Duck Typing

<a name="-duck-typing-to-pattern"></a>
### `to_pattern`

All methods converting string input to pattern objects will also accept any arbitrary object that implements `to_pattern`:

``` ruby
require 'mustermann'

class MyObject
  def to_pattern(**options)
    Mustermann.new("/foo", **options)
  end
end

object = MyObject.new
Mustermann.new(object, type: :rails) # => #<Mustermann::Rails:"/foo">
```

<a name="-duck-typing-respond-to"></a>
### `respond_to?`

You can and should use `respond_to?` to check if a pattern supports certain features.

``` ruby
require 'mustermann'
pattern = Mustermann.new("/")

puts "supports expanding"             if pattern.respond_to? :expand
puts "supports generating templates"  if pattern.respond_to? :to_templates
```

Alternatively, you can handle a `NotImplementedError` raised from such a method.

``` ruby
require 'mustermann'
pattern = Mustermann.new("/")

begin
  p pattern.to_templates
rescue NotImplementedError
  puts "does not support generating templates"
end
```

This behavior corresponds to what Ruby does, for instance for [`fork`](http://ruby-doc.org/core-2.1.1/NotImplementedError.html).

<a name="-available-options"></a>
## Available Options

<a name="-available-options--capture"></a>
### `capture`

Supported by: All types except `identity`, `shell` and `simple` patterns.

Most pattern types support changing the strings named captures will match via the `capture` options.

Possible values for a capture:

``` ruby
# String: Matches the given string (or any URI encoded version of it)
Mustermann.new('/index.:ext', capture: 'png')

# Regexp: Matches the Regular expression
Mustermann.new('/:id', capture: /\d+/)

# Symbol: Matches POSIX character class
Mustermann.new('/:id', capture: :digit)

# Array of the above: Matches anything in the array
Mustermann.new('/:id_or_slug', capture: [/\d+/, :word])

# Hash of the above: Looks up the hash entry by capture name and uses value for matching
Mustermann.new('/:id.:ext', capture: { id: /\d+/, ext: ['png', 'jpg'] })
```

Available POSIX character classes are: `:alnum`, `:alpha`, `:blank`, `:cntrl`, `:digit`, `:graph`, `:lower`, `:print`, `:punct`, `:space`, `:upper`, `:xdigit`, `:word` and `:ascii`.

<a name="-available-options--except"></a>
### `except`

Supported by: All types except `identity`, `shell` and `simple` patterns.

Given you supply a second pattern via the except option. Any string that would match the primary pattern but also matches the except pattern will not result in a successful match. Feel free to read that again. Or just take a look at this example:

``` ruby
pattern = Mustermann.new('/auth/*', except: '/auth/login')
pattern === '/auth/dunno' # => true
pattern === '/auth/login' # => false
```

Now, as said above, `except` treats the value as a pattern:

``` ruby
pattern = Mustermann.new('/*anything', type: :rails, except: '/*anything.png')
pattern === '/foo.jpg' # => true
pattern === '/foo.png' # => false
```

<a name="-available-options--greedy"></a>
### `greedy`

Supported by: All types except `identity` and `shell` patterns.
Default value: `true`

**Simple** patterns are greedy, meaning that for the pattern `:foo:bar?`, everything will be captured as `foo`, `bar` will always be `nil`. By setting `greedy` to `false`, `foo` will capture as little as possible (which in this case would only be the first letter), leaving the rest to `bar`.

**All other** supported patterns are semi-greedy. This means `:foo(.:bar)?` (`:foo(.:bar)` for Rails patterns) will capture everything before the *last* dot as `foo`. For these two pattern types, you can switch into non-greedy mode by setting the `greedy` option to false. In that case `foo` will only capture the part before the *first* dot.

Semi-greedy behavior is not specific to dots, it works with all characters or strings. For instance, `:a(foo:b)` will capture everything before the *last* `foo` as `a`, and `:foo(bar)?` will not capture a `bar` at the end.

``` ruby
pattern = Mustermann.new(':a.:b', greedy: true)
pattern.match('a.b.c.d') # => #<MatchData a:"a.b.c" b:"d">

pattern = Mustermann.new(':a.:b', greedy: false)
pattern.match('a.b.c.d') # => #<MatchData a:"a" b:"b.c.d">
```

<a name="-available-options--space_matches_plus"></a>
### `space_matches_plus`

Supported by: All types except `identity`, `regexp` and `shell` patterns.
Default value: `true`

Most pattern types will by default also match a plus sign for a space in the pattern:

``` ruby
Mustermann.new('a b') === 'a+b' # => true
```

You can disable this behavior via `space_matches_plus`:

``` ruby
Mustermann.new('a b', space_matches_plus: false) === 'a+b' # => false
```

**Important:** This setting has no effect on captures, captures will always keep plus signs as plus sings and spaces as spaces:

``` ruby
pattern = Mustermann.new(':x')
pattern.match('a b')[:x] # => 'a b'
pattern.match('a+b')[:x] # => 'a+b'
````

<a name="-available-options--uri_decode"></a>
### `uri_decode`

Supported by all pattern types.
Default value: `true`

Usually, characters in the pattern will also match the URI encoded version of these characters:

``` ruby
Mustermann.new('a b') === 'a b'   # => true
Mustermann.new('a b') === 'a%20b' # => true
```

You can avoid this by setting `uri_decode` to `false`:

``` ruby
Mustermann.new('a b', uri_decode: false) === 'a b'   # => true
Mustermann.new('a b', uri_decode: false) === 'a%20b' # => false
```

<a name="-available-options--ignore_unknown_options"></a>
### `ignore_unknown_options`

Supported by all patterns.
Default value: `false`

If you pass an option in that is not supported by the specific pattern type, Mustermann will raise an `ArgumentError`.
By setting `ignore_unknown_options` to `true`, it will happily ignore the option.

<a name="-performance"></a>
## Performance

Mustermann is designed so that as much work as possible happens at object-creation time, keeping matching and expansion fast at request time. Pattern objects should be treated as immutable; their internals are optimized for both speed and low memory usage.

Key points:

* **Pattern caching:** `Mustermann.new` may return the same instance for identical arguments while that instance is still alive. Do not rely on object identity.
* **Single-pattern matching:** AST-based patterns (sinatra, rails, hybrid, template, flask) use bounded character classes, negative look-ahead, and non-greedy splats to avoid unnecessary backtracking in Ruby's Oniguruma engine. Using a pattern as a `Regexp` replacement adds at most one method-dispatch of overhead.
* **Routing with `Mustermann::Set`:** Uses a trie (prefix tree) for large tables. Rather than checking every route in sequence, the trie walks the input one character at a time, sharing prefix traversal across all patterns that start with the same characters. Dispatch time grows far more slowly than a linear scan. A `use_trie:` threshold (default 50) controls when the switch happens, and an optional `ObjectSpace::WeakKeyMap` cache avoids re-matching the same string.
* **Expansion:** Most computation is shifted to compile time. Memory grows linearly with the number of optional-key combinations in a pattern.

See **[docs/performance.md](../docs/performance.md)** for a detailed explanation of each optimization, the linear vs. trie trade-off, caching, thread-safety, and benchmark guidance.

## Details on Pattern Types

- [`identity`](../docs/patterns/identity.md)
- [`regexp`](../docs/patterns/regexp.md)
- [`sinatra`](../docs/patterns/sinatra.md)
- [`rails`](../docs/patterns/rails.md)
- [`hybrid`](../docs/patterns/hybrid.md)
