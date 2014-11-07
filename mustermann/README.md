# The Amazing Mustermann

[![Build Status](https://travis-ci.org/rkh/mustermann.svg?branch=master)](https://travis-ci.org/rkh/mustermann) [![Coverage Status](http://img.shields.io/coveralls/rkh/mustermann.svg?branch=master)](https://coveralls.io/r/rkh/mustermann) [![Code Climate](http://img.shields.io/codeclimate/github/rkh/mustermann.svg)](https://codeclimate.com/github/rkh/mustermann) [![Dependency Status](https://gemnasium.com/rkh/mustermann.svg)](https://gemnasium.com/rkh/mustermann) [![Gem Version](http://img.shields.io/gem/v/mustermann.svg)](https://rubygems.org/gems/mustermann)
[![Inline docs](http://inch-ci.org/github/rkh/mustermann.svg)](http://inch-ci.org/github/rkh/mustermann)
[![Documentation](http://img.shields.io/:yard-docs-38c800.svg)](http://rubydoc.info/gems/mustermann/frames)
[![License](http://img.shields.io/:license-MIT-38c800.svg)](http://rkh.mit-license.org)
[![Badges](http://img.shields.io/:badges-9/9-38c800.svg)](http://img.shields.io) 


*Make sure you view the correct docs: [latest release](http://rubydoc.info/gems/mustermann/frames), [master](http://rubydoc.info/github/rkh/mustermann/master/frames).*

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
* **[Binary Operators](#-binary-operators):** Patterns can be combined into composite patterns using binary operators.
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

* **[String Scanner](#-string-scanner):** It comes with a version of Ruby's [StringScanner](http://ruby-doc.org/stdlib-2.0/libdoc/strscan/rdoc/StringScanner.html) made for pattern objects.
* **[Mapper](#-mapper):** A simple tool for mapping one string to another based on patterns.
* **[Routers](#-routers):** Model execution flow based on pattern matching. Comes with a simple Rack router.
* **[Sinatra Integration](#-sinatra-integration):** Mustermann can be used as a [Sinatra](http://www.sinatrarb.com/) extension. Sinatra 2.0 and beyond will use Mustermann by default.

### More Infos

* **[Requirements](#-requirements):** Mustermann currently requires Ruby 2.0 or later.
* **[Release History](#-release-history):** See what's new.

<a name="-pattern-types"></a>
## Pattern Types

Mustermann support multiple pattern types. A pattern type defines the syntax, matching semantics and whether certain features, like [expanding](#-expanding) and [generating templates](#-generating-templates), are available.

You can create a pattern of a certain type by passing `type` option to `Mustermann.new`:

``` ruby
require 'mustermann'
pattern = Mustermann.new('/*/**', type: :shell)
```

Note that this will use the type as suggestion: When passing in a string argument, it will create a pattern of the given type, but it might choose a different type for other objects (a regular expression argument will always result in a [regexp](#-pattern-details-regexp) pattern, a symbol always in a [sinatra](#-pattern-details-sinatra) pattern, etc).

Alternatively, you can also load and instantiate the pattern type directly:

``` ruby
require 'mustermann/shell'
pattern = Mustermann::Shell.new('/*/**')
```

### Available Types

<table>
  <thead>
    <tr>
      <th>Type</th>
      <th>Example</th>
      <th>Compatible with</th>
      <th>Notes</th>
    </tr>
  </thead>
  <tbody>

    <tr>
      <th><a href="#-pattern-details-cake"><tt>cake</tt></a></th>
      <td><tt>/:prefix/**</tt></td>
      <td><a href="http://cakephp.org/">CakePHP</a></td>
      <td></td>
    </tr>

    <tr>
      <th><a href="#-pattern-details-express"><tt>express</tt></a></th>
      <td><tt>/:prefix+/:id(\d+)</tt></td>
      <td>
        <a href="http://expressjs.com/">Express</a>,
        <a href="https://pillarjs.github.io/">pillar.js</a>
      </td>
      <td></td>
    </tr>

    <tr>
      <th><a href="#-pattern-details-flask"><tt>flask</tt></a></th>
      <td><tt>/&lt;prefix&gt;/&lt;int:id&gt;</tt></td>
      <td>
        <a href="http://flask.pocoo.org/">Flask</a>,
        <a href="http://werkzeug.pocoo.org/">Werkzeug</a>,
        <a href="http://bottlepy.org/docs/dev/index.html">Bottle</a>
      </td>
      <td></td>
    </tr>

    <tr>
      <th><a href="#-pattern-details-identity"><tt>identity</tt></a></th>
      <td><tt>/image.png</tt></td>
      <td>any software using strings</td>
      <td>
        Exact string matching (no parameter parsing).<br>
        Does not support expanding.
      </td>
    </tr>

    <tr>
      <th><a href="#-pattern-details-pyramid"><tt>pyramid</tt></a></th>
      <td><tt>/{prefix:.*}/{id}</tt></td>
      <td>
        <a href="http://www.pylonsproject.org/projects/pyramid/about">Pyramid</a>,
        <a href="http://www.pylonsproject.org/projects/pylons-framework/about">Pylons</a>
      </td>
      <td></td>
    </tr>

    <tr>
      <th><a href="#-pattern-details-rails"><tt>rails</tt></a></th>
      <td><tt>/:slug(.:ext)</tt></td>
      <td>
        <a href="http://rubyonrails.org/">Ruby on Rails</a>,
        <a href="https://github.com/joshbuddy/http_router">HTTP Router</a>,
        <a href="http://lotusrb.org/">Lotus</a>,
        <a href="http://www.scalatra.org/">Scalatra</a> (if <a href="http://www.scalatra.org/2.3/guides/http/routes.html#toc_248">configured</a>)</td>
      <td></td>
    </tr>

    <tr>
      <th><a href="#-pattern-details-regexp"><tt>regexp</tt></a></th>
      <td><tt>/(?&lt;slug&gt;[^\/]+)</tt></td>
      <td>
        <a href="http://www.geocities.jp/kosako3/oniguruma/">Oniguruma</a>,
        <a href="https://github.com/k-takata/Onigmo">Onigmo<a>,
        regular expressions
      </td>
      <td>
        Created when you pass a regexp to <tt>Mustermann.new</tt>.<br>
        Does not support expanding or generating templates.
      </td>
    </tr>

    <tr>
      <th><a href="#-pattern-details-shell"><tt>shell</tt></a></th>
      <td><tt>/*.{png,jpg}</tt></td>
      <td>Unix Shell (bash, zsh)</td>
      <td>Does not support expanding or generating templates.</td>
    </tr>

    <tr>
      <th><a href="#-pattern-details-simple"><tt>simple</tt></a></th>
      <td><tt>/:slug.:ext</tt></td>
      <td>
        <a href="http://www.sinatrarb.com/">Sinatra</a> (1.x),
        <a href="http://www.scalatra.org/">Scalatra</a>,
        <a href="http://perldancer.org/">Dancer</a>
      </td>
      <td>
        Implementation is a direct copy from Sinatra 1.3.<br>
        Does not support expanding or generating templates.
      </td>
    </tr>

    <tr>
      <th><a href="#-pattern-details-sinatra"><tt>sinatra</tt></a></th>
      <td><tt>/:slug(.:ext)?</tt></td>
      <td>
        <a href="http://www.sinatrarb.com/">Sinatra</a> (2.x),
        <a href="http://www.padrinorb.com/">Padrino</a> (>= 0.13.0),
        <a href="https://github.com/namusyaka/pendragon">Pendragon</a>,
        <a href="https://github.com/kenichi/angelo">Angelo</a>
      </td>
      <td>
        <u>This is the default</u> and the only type "invented here".<br>
        It is a superset of <tt>simple</tt> and has a common subset with
        <tt>template</tt> (and others).
      </td>
    </tr>

    <tr>
      <th><a href="#-pattern-details-sinatra"><tt>template</tt></a></th>
      <td><tt>/{+pre}/{page}{?q}</tt></td>
      <td>
        <a href="https://tools.ietf.org/html/rfc6570">RFC 6570</a>,
        <a href="http://jsonapi.org/">JSON API</a>,
        <a href="http://tools.ietf.org/html/draft-nottingham-json-home-02">JSON Home Documents</a>
        and <a href="https://code.google.com/p/uri-templates/wiki/Implementations">many more</a>
      </td>
      <td>Standardized URI templates, can be <a href="#-generating-templates">generated</a> from most other types.</td>
    </tr>
  </tbody>
</table>

Any software using Mustermann is obviously compatible with at least one of the above.

### Why so many?

Short answer: **Why not?**

You are probably concerned about one of these issues:

* **Code base complexity:** Most of these pattern implementations are very short and simple. The `cake` definition is two lines long, the `rails` implementation four lines.
* **Memory cost:** If you don't explicitly load one of these implementations and don't create any patterns of that type, the implementation itself will not be loaded. The only memory it uses it one more entry in the list of available pattern types.

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
pattern.names          # => ['page']
pattern.names          # => {"page"=>[1]}

pattern = Mustermann.new('/home', type: :identity)
pattern.match('/')     # => nil
pattern.match('/home') # => #<Mustermann::SimpleMatch "/home">
pattern =~ '/home'     # => 0
pattern === '/home'    # => true (this allows using it in case statements)
pattern.names          # => []
pattern.names          # => {}
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
* `peek_match` will return a `MatchData` or `Mustermann::SimpleMatch` (just like `match` does for the full string)
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
pattern.expan(:append, slug: "foo", value: "bar") # => "/foo?value=bar"
```

<a name="-generating-templates"></a>
## Generating Templates

... TODO ...

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

<a name="-string-scanner"></a>
## String Scanner

... TODO ...

<a name="-mapper"></a>
## Mapper


You can use a mapper to transform strings according to two or more mappings:

``` ruby
require 'mustermann/mapper'

mapper = Mustermann::Mapper.new("/:page(.:format)?" => ["/:page/view.:format", "/:page/view.html"])
mapper['/foo']     # => "/foo/view.html"
mapper['/foo.xml'] # => "/foo/view.xml"
mapper['/foo/bar'] # => "/foo/bar"
```

<a name="-routers"></a>
## Routers

Mustermann comes with basic router implementations that will call certain callbacks depending on the input.

### Simple Router

The simple router chooses callbacks based on an input string.

``` ruby
require 'mustermann/router/simple'

router = Mustermann::Router::Simple.new(default: 42)
router.on(':name', capture: :digit) { |string| string.to_i }
router.call("23")      # => 23
router.call("example") # => 42
```

### Rack Router

This is not a full replacement for Rails, Sinatra, Cuba, etc, as it only cares about path based routing.

``` ruby
require 'mustermann/router/rack'

router = Mustermann::Router::Rack.new do
  on '/' do |env|
    [200, {'Content-Type' => 'text/plain'}, ['Hello World!']]
  end

  on '/:name' do |env|
    name = env['mustermann.params']['name']
    [200, {'Content-Type' => 'text/plain'}, ["Hello #{name}!"]]
  end

  on '/something/*', call: SomeApp
end

# in a config.ru
run router
```
<a name="-sinatra-integration"></a>
## Sinatra Integration

All patterns implement `match`, which means they can be dropped into Sinatra and other Rack routers:

``` ruby
require 'sinatra'
require 'mustermann'

get Mustermann.new('/:foo') do
  params[:foo]
end
```

In fact, since using this with Sinatra is the main use case, it comes with a build-in extension for **Sinatra 1.x**.

``` ruby
require 'sinatra'
require 'mustermann'

register Mustermann

# this will use Mustermann rather than the built-in pattern matching
get '/:slug(.ext)?' do
  params[:slug]
end
```

### Configuration

You can change what pattern type you want to use for your app via the `pattern` option:

``` ruby
require 'sinatra/base'
require 'mustermann'

class MyApp < Sinatra::Base
  register Mustermann
  set :pattern, type: :shell

  get '/images/*.png' do
    send_file request.path_info
  end

  get '/index{.htm,.html,}' do
    erb :index
  end
end
```

You can use the same setting for options:

``` ruby
require 'sinatra'
require 'mustermann'

register Mustermann
set :pattern, capture: { ext: %w[png jpg html txt] }

get '/:slug(.:ext)?' do
  # slug will be 'foo' for '/foo.png'
  # slug will be 'foo.bar' for '/foo.bar'
  # slug will be 'foo.bar' for '/foo.bar.html'
  params[:slug]
end
```

It is also possible to pass in options to a specific route:

``` ruby
require 'sinatra'
require 'mustermann'

register Mustermann

get '/:slug(.:ext)?', pattern: { greedy: false } do
  # slug will be 'foo' for '/foo.png'
  # slug will be 'foo' for '/foo.bar'
  # slug will be 'foo' for '/foo.bar.html'
  params[:slug]
end
```

Of course, all of the above can be combined.
Moreover, the `capture` and the `except` option can be passed to route directly.
And yes, this also works with `before` and `after` filters.

``` ruby
require 'sinatra/base'
require 'sinatra/respond_with'
require 'mustermann'

class MyApp < Sinatra::Base
  register Mustermann, Sinatra::RespondWith
  set :pattern, capture: { id: /\d+/ } # id will only match digits

  # only capture extensions known to Rack
  before '*:ext', capture: Rack::Mime::MIME_TYPES.keys do
    content_type params[:ext]                 # set Content-Type
    request.path_info = params[:splat].first  # drop the extension
  end

  get '/:id' do
    not_found unless page = Page.find params[:id]
    respond_with(page)
  end
end
```

### Why would I want this?

* It gives you fine grained control over the pattern matching
* Allows you to use different pattern styles in your app
* The default is more robust and powerful than the built-in patterns
* Sinatra 2.0 will use Mustermann internally
* Better exceptions for broken route syntax

### Why not include this in Sinatra 1.x?

* It would introduce breaking changes, even though these would be minor
* Like Sinatra 2.0, Mustermann requires Ruby 2.0 or newer

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

It might also be that you want to call `to_pattern` yourself instead of `Mustermann.new`. You can load `mustermann/to_pattern` to implement this method for strings, regular expressions and pattern objects:

``` ruby
require 'mustermann/to_pattern'

"/foo".to_pattern               # => #<Mustermann::Sinatra:"/foo">
"/foo".to_pattern(type: :rails) # => #<Mustermann::Rails:"/foo">
%r{/foo}.to_pattern             # => #<Mustermann::Regular:"\\/foo">
"/foo".to_pattern.to_pattern    # => #<Mustermann::Sinatra:"/foo">
```

You can also use the `Mustermann::ToPattern` mixin to easily add `to_pattern` to your own objects:

``` ruby
require 'mustermann/to_pattern'

class MyObject
  include Mustermann::ToPattern

  def to_s
    "/foo"
  end
end

MyObject.new.to_pattern # => #<Mustermann::Sinatra:"/foo">
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

<a name="-available-options--converters"></a>
### `converters`

Supported by `flask` patterns.
Default value: `{}`

[Flask patterns](#-pattern-details-flask) support registering custom converters.

A converter object may implement any of the following methods:

* `convert`: Should return a block converting a string value to whatever value should end up in the `params` hash.
* `constraint`: Should return a regular expression limiting which input string will match the capture.
* `new`: Returns an object that may respond to `convert` and/or `constraint` as described above. Any arguments used for the converter inside the pattern will be passed to `new`.

``` ruby
require 'mustermann'

SimpleConverter = Struct.new(:constraint, :convert)
id_converter    = SimpleConverter.new(/\d/, -> s { s.to_i })

class NumConverter
  def initialize(base: 10)
    @base = Integer(base)
  end

  def convert
    -> s { s.to_i(@base) }
  end

  def constraint
    @base > 10 ? /[\da-#{(@base-1).to_s(@base)}]/ : /[0-#{@base-1}]/
  end
end

pattern = Mustermann.new('/<id:id>/<num(base=8):oct>/<num(base=16):hex>',
  type: :flask, converters: { id: id_converter, num: NumConverter})

pattern.params('/10/12/f1') # => {"id"=>10, "oct"=>10, "hex"=>241}
```

<a name="-available-options--ignore_unknown_options"></a>
### `ignore_unknown_options`

Supported by all patterns.
Default value: `false`

If you pass an option in that is not supported by the specific pattern type, Mustermann will raise an `ArgumentError`.
By setting `ignore_unknown_options` to `true`, it will happily ignore the option.

<a name="-performance"></a>
## Performance

It's generally a good idea to reuse pattern objects, since as much computation as possible is happening during object creation, so that the actual matching or expanding is quite fast.

Pattern objects should be treated as immutable. Their internals have been designed for both performance and low memory usage. To reduce pattern compilation, `Mustermann.new` and `Mustermann::Pattern.new` might return the same instance when given the same arguments, if that instance has not yet been garbage collected. However, this is not guaranteed, so do not rely on object identity.

### String Matching

When using a pattern instead of a regular expression for string matching, performance will usually be comparable.

In certain cases, Mustermann might outperform naive, equivalent regular expressions. It achieves this by using look-ahead and atomic groups in ways that work well with a backtracking, NFA-based regular expression engine (such as the Oniguruma/Onigmo engine used by Ruby). It can be difficult and error prone to construct complex regular expressions using these techniques by hand. This only applies to patterns generating an AST internally (all but [identity](#-pattern-details-identity), [shell](#-pattern-details-shell), [simple](#-pattern-details-simple) and [regexp](#-pattern-details-regexp) patterns).

When using a Mustermann pattern as a direct Regexp replacement (ie, via methods like `=~`, `match` or `===`), the overhead will be a single method dispatch, which some Ruby implementations might even eliminate with method inlining. This only applies to patterns using a regular expression internally (all but [identity](#-pattern-details-identity) and [shell](#-pattern-details-shell) patterns).

### Expanding

Pattern expansion significantly outperforms other, widely used Ruby tools for generating URLs from URL patterns in most use cases.

This comes with a few trade-offs:

* As with pattern compilation, as much computation as possible has been shifted to compiling expansion rules. This will add compilation overhead, which is why patterns only generate these rules on the first invocation to `Mustermann::Pattern#expand`. Create a `Mustermann::Expander` instance yourself to get better control over the point in time this computation should happen.
* Memory is sacrificed in favor of performance: The size of the expander object will grow linear with the number of possible combination for expansion keys ("/:foo/:bar" has one such combination, but "/(:foo/)?:bar?" has four)
* Parsing a params hash from a string generated from another params hash might not result in two identical hashes, and vice versa. Specifically, expanding ignores capture constraints, type casting and greediness.
* Partial expansion is (currently) not supported.

## Details on Pattern Types

<a name="-pattern-details-cake"></a>
### `cake`

**Supported options:**
[`capture`](#-available-options--capture),
[`except`](#-available-options--except),
[`greedy`](#-available-options--greedy),
[`space_matches_plus`](#-available-options--space_matches_plus),
[`uri_decode`](#-available-options--uri_decode),
[`ignore_unknown_options`](#-available-options--ignore_unknown_options).

**External documentation:**
[CakePHP 2.0 Routing](http://book.cakephp.org/2.0/en/development/routing.html),
[CakePHP 3.0 Routing](http://book.cakephp.org/3.0/en/development/routing.html)

<a name="-pattern-details-express"></a>
### `express`

**Supported options:**
[`capture`](#-available-options--capture),
[`except`](#-available-options--except),
[`greedy`](#-available-options--greedy),
[`space_matches_plus`](#-available-options--space_matches_plus),
[`uri_decode`](#-available-options--uri_decode),
[`ignore_unknown_options`](#-available-options--ignore_unknown_options).

**External documentation:**
[path-to-regexp](https://github.com/pillarjs/path-to-regexp#path-to-regexp),
[live demo](http://forbeslindesay.github.io/express-route-tester/)

<a name="-pattern-details-flask"></a>
### `flask`

**Supported options:**
[`capture`](#-available-options--capture),
[`except`](#-available-options--except),
[`greedy`](#-available-options--greedy),
[`space_matches_plus`](#-available-options--space_matches_plus),
[`uri_decode`](#-available-options--uri_decode),
[`converters`](#-available-options--converters),
[`ignore_unknown_options`](#-available-options--ignore_unknown_options).

**External documentation:**
[Werkzeug: URL Routing](http://werkzeug.pocoo.org/docs/0.9/routing/)

<a name="-pattern-details-identity"></a>
### `identity`

**Supported options:**
[`uri_decode`](#-available-options--uri_decode),
[`ignore_unknown_options`](#-available-options--ignore_unknown_options).

<table>
  <thead>
    <tr>
      <th>Syntax Element</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><i>any character</i></td>
      <td>Matches exactly that character or a URI escaped version of it.</td>
    </tr>
  </tbody>
</table>

<a name="-pattern-details-pyramid"></a>
### `pyramid`

**Supported options:**
[`capture`](#-available-options--capture),
[`except`](#-available-options--except),
[`greedy`](#-available-options--greedy),
[`space_matches_plus`](#-available-options--space_matches_plus),
[`uri_decode`](#-available-options--uri_decode),
[`ignore_unknown_options`](#-available-options--ignore_unknown_options).

<a name="-pattern-details-rails"></a>
### `rails`

**Supported options:**
[`capture`](#-available-options--capture),
[`except`](#-available-options--except),
[`greedy`](#-available-options--greedy),
[`space_matches_plus`](#-available-options--space_matches_plus),
[`uri_decode`](#-available-options--uri_decode),
[`ignore_unknown_options`](#-available-options--ignore_unknown_options).

<table>
  <thead>
    <tr>
      <th>Syntax Element</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><b>:</b><i>name</i></td>
      <td>
        Captures anything but a forward slash in a semi-greedy fashion. Capture is named <i>name</i>.
        Capture behavior can be modified with <a href="#capture"><tt>capture</tt></a> and <a href="#greedy"><tt>greedy</tt></a> option.
      </td>
    </tr>
    <tr>
      <td><b>*</b><i>name</i></td>
      <td>
        Captures anything in a non-greedy fashion. Capture is named <i>name</i>.
      </td>
    </tr>
    <tr>
      <td><b>(</b><i>expression</i><b>)</b></td>
      <td>Enclosed <i>expression</i> is optional.</td>
    </tr>
    <tr>
      <td><b>/</b></td>
      <td>
        Matches forward slash. Does not match URI encoded version of forward slash.
      </td>
    </tr>
    <tr>
      <td><i>any other character</i></td>
      <td>Matches exactly that character or a URI encoded version of it.</td>
    </tr>
  </tbody>
</table>

<a name="-pattern-details-regexp"></a>
### `regexp`

**Supported options:**
[`uri_decode`](#-available-options--uri_decode),
[`ignore_unknown_options`](#-available-options--ignore_unknown_options).

<table>
  <thead>
    <tr>
      <th>Syntax Element</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><i>any string</i></td>
      <td>Interpreted as regular expression.</td>
    </tr>
  </tbody>
</table>

<a name="-pattern-details-shell"></a>
### `shell`

**Supported options:**
[`uri_decode`](#-available-options--uri_decode),
[`ignore_unknown_options`](#-available-options--ignore_unknown_options).

<table>
  <thead>
    <tr>
      <th>Syntax Element</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><b>*</b></td>
      <td>Matches anything but a slash.</td>
    </tr>
    <tr>
      <td><b>**</b></td>
      <td>Matches anything.</td>
    </tr>
    <tr>
      <td><b>[</b><i>set</i><b>]</b></td>
      <td>Matches one character in <i>set</i>.</td>
    </tr>
    <tr>
      <td><b>&#123;</b><i>a</i>,<i>b</i><b>&#125;</b></td>
      <td>Matches <i>a</i> or <i>b</i>.</td>
    </tr>
    <tr>
      <td><b>\</b><i>x</i></td>
      <td>Matches <i>x</i> or URI encoded version of <i>x</i>. For instance <tt>\*</tt> matches <tt>*</tt>.</td>
    </tr>
    <tr>
      <td><i>any other character</i></td>
      <td>Matches exactly that character or a URI encoded version of it.</td>
    </tr>
  </tbody>
</table>

<a name="-pattern-details-simple"></a>
### `simple`

**Supported options:**
[`greedy`](#-available-options--greedy),
[`space_matches_plus`](#-available-options--space_matches_plus),
[`uri_decode`](#-available-options--uri_decode),
[`ignore_unknown_options`](#-available-options--ignore_unknown_options).

<table>
  <thead>
    <tr>
      <th>Syntax Element</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><b>:</b><i>name</i></td>
      <td>
        Captures anything but a forward slash in a greedy fashion. Capture is named <i>name</i>.
      </td>
    </tr>
    <tr>
      <td><b>*</b></td>
      <td>
        Captures anything in a non-greedy fashion. Capture is named splat.
        It is always an array of captures, as you can use <tt>*</tt> more than once in a pattern.
      </td>
    </tr>
    <tr>
      <td><i>x</i><b>?</b></td>
      <td>Makes <i>x</i> optional. For instance <tt>foo?</tt> matches <tt>foo</tt> or <tt>fo</tt>.</td>
    </tr>
    <tr>
      <td><b>/</b></td>
      <td>
        Matches forward slash. Does not match URI encoded version of forward slash.
      </td>
    </tr>
    <tr>
      <td><i>any special character</i></td>
      <td>Matches exactly that character or a URI encoded version of it.</td>
    </tr>
    <tr>
      <td><i>any other character</i></td>
      <td>Matches exactly that character.</td>
    </tr>
  </tbody>
</table>

<a name="-pattern-details-sinatra"></a>
### `sinatra`

**Supported options:**
[`capture`](#-available-options--capture),
[`except`](#-available-options--except),
[`greedy`](#-available-options--greedy),
[`space_matches_plus`](#-available-options--space_matches_plus),
[`uri_decode`](#-available-options--uri_decode),
[`ignore_unknown_options`](#-available-options--ignore_unknown_options).

<table>
  <thead>
    <tr>
      <th>Syntax Element</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><b>:</b><i>name</i> <i><b>or</b></i> <b>&#123;</b><i>name</i><b>&#125;</b></td>
      <td>
        Captures anything but a forward slash in a semi-greedy fashion. Capture is named <i>name</i>.
        Capture behavior can be modified with <a href="#capture"><tt>capture</tt></a> and <a href="#greedy"><tt>greedy</tt></a> option.
      </td>
    </tr>
    <tr>
      <td><b>*</b><i>name</i> <i><b>or</b></i> <b>&#123;+</b><i>name</i><b>&#125;</b></td>
      <td>
        Captures anything in a non-greedy fashion. Capture is named <i>name</i>.
      </td>
    </tr>
    <tr>
      <td><b>*</b> <i><b>or</b></i> <b>&#123;+splat&#125;</b></td>
      <td>
        Captures anything in a non-greedy fashion. Capture is named splat.
        It is always an array of captures, as you can use it more than once in a pattern.
      </td>
    </tr>
    <tr>
      <td><b>(</b><i>expression</i><b>)</b></td>
      <td>
        Enclosed <i>expression</i> is a group. Useful when combined with <tt>?</tt> to make it optional,
        or to separate two elements that would otherwise be parsed as one.
      </td>
    </tr>
    <tr>
      <td><b>(</b><i>expression</i><b>|</b><i>expression</i><b>|</b><i>...</i><b>)</b></td>
      <td>
        Will match anything matching the nested expressions. May contain any other syntax element, including captures.
      </td>
    </tr>
    <tr>
      <td><i>x</i><b>?</b></td>
      <td>Makes <i>x</i> optional. For instance, <tt>(foo)?</tt> matches <tt>foo</tt> or an empty string.</td>
    </tr>
    <tr>
      <td><b>/</b></td>
      <td>
        Matches forward slash. Does not match URI encoded version of forward slash.
      </td>
    </tr>
    <tr>
      <td><b>\</b><i>x</i></td>
      <td>Matches <i>x</i> or URI encoded version of <i>x</i>. For instance <tt>\*</tt> matches <tt>*</tt>.</td>
    </tr>
    <tr>
      <td><i>any other character</i></td>
      <td>Matches exactly that character or a URI encoded version of it.</td>
    </tr>
  </tbody>
</table>

<a name="-pattern-details-template"></a>
### `template`

**Supported options:**
[`capture`](#-available-options--capture),
[`except`](#-available-options--except),
[`greedy`](#-available-options--greedy),
[`space_matches_plus`](#-available-options--space_matches_plus),
[`uri_decode`](#-available-options--uri_decode),
[`ignore_unknown_options`](#-available-options--ignore_unknown_options).

<table>
  <thead>
    <tr>
      <th>Syntax Element</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><b>&#123;</b><i>o</i> <i>var</i> <i>m</i><b>,</b> <i>var</i> <i>m</i><b>,</b> ...<b>&#125;</b></td>
      <td>
        Captures expansion.
        Operator <i>o</i>: <code>+ # . / ; ? &amp;</tt> or none.
        Modifier <i>m</i>: <code>:num *</tt> or none.
      </td>
    </tr>
    <tr>
      <td><b>/</b></td>
      <td>
        Matches forward slash. Does not match URI encoded version of forward slash.
      </td>
    </tr>
    <tr>
      <td><i>any other character</i></td>
      <td>Matches exactly that character or a URI encoded version of it.</td>
    </tr>
  </tbody>
</table>

The operators `+` and `#` will always match non-greedy, whereas all other operators match semi-greedy by default.
All modifiers and operators are supported. However, it does not parse lists as single values without the *explode* modifier (aka *star*).
Parametric operators (`;`, `?` and `&`) currently only match parameters in given order.

Please keep the following in mind:

> "Some URI Templates can be used in reverse for the purpose of variable matching: comparing the template to a fully formed URI in order to extract the variable parts from that URI and assign them to the named variables.  Variable matching only works well if the template expressions are delimited by the beginning or end of the URI or by characters that cannot be part of the expansion, such as reserved characters surrounding a simple string expression.  In general, regular expression languages are better suited for variable matching."
> &mdash; *RFC 6570, Sec 1.5: "Limitations"*

Note that it differs from URI templates in that it takes the unescaped version of special character instead of the escaped version.

If you reuse the exact same templates and expose them via an external API meant for expansion,
you should set `uri_decode` to `false` in order to conform with the specification.

If you are looking for an alternative implementation that also supports expanding, check out [addressable](http://addressable.rubyforge.org/).

<a name="-requirements"></a>
## Requirements

Mustermann depends on [tool](https://github.com/rkh/tool) (which has been extracted from Mustermann and Sinatra 2.0), and a Ruby 2.0 compatible Ruby implementation.

It is known to work on MRI 2.0 and 2.1.

**JRuby** is not yet fully supported. It is possible to run parts of Mustermann by passing in `--2.0 -X-C`, but as of JRuby 1.7, we would recommend waiting for proper Ruby 2.0 support to land in JRuby. The same goes for **Rubinius**.

If you need Ruby 1.9 support, you might be able to use the **unofficial** [mustermann19](http://rubygems.org/gems/mustermann19) gem based on [namusyaka's fork](https://github.com/namusyaka/mustermann).

<a name="-release-history"></a>
## Release History

Mustermann follows [Semantic Versioning 2.0](http://semver.org/). Anything documented in the README or via YARD and not declared private is part of the public API.

### Stable Releases

There have been no stable releases yet. The code base is considered solid but I only know of a small number of actual production usage.
As there has been no stable release yet, the API might still change, though I consider this unlikely.

### Development Releases

* **Mustermann 0.3.1** (2014-09-12)
    * More Infos:
      [RubyGems.org](http://rubygems.org/gems/mustermann/versions/0.3.1),
      [RubyDoc.info](http://rubydoc.info/gems/mustermann/0.3.1/frames),
      [GitHub.com](https://github.com/rkh/mustermann/tree/v0.3.1)
    * Speed up pattern generation and matching (thanks [Daniel Mendler](https://github.com/minad))
    * Small change so `Mustermann === Mustermann.new('...')` returns `true`.
* **Mustermann 0.3.0** (2014-08-18)
    * More Infos:
      [RubyGems.org](http://rubygems.org/gems/mustermann/versions/0.3.0),
      [RubyDoc.info](http://rubydoc.info/gems/mustermann/0.3.0/frames),
      [GitHub.com](https://github.com/rkh/mustermann/tree/v0.3.0)
    * Add `regexp` pattern.
    * Add named splats to Sinatra patterns.
    * Add `Mustermann::Mapper`.
    * Improve duck typing support.
    * Improve documentation.
* **Mustermann 0.2.0** (2013-08-24)
    * More Infos:
      [RubyGems.org](http://rubygems.org/gems/mustermann/versions/0.2.0),
      [RubyDoc.info](http://rubydoc.info/gems/mustermann/0.2.0/frames),
      [GitHub.com](https://github.com/rkh/mustermann/tree/v0.2.0)
    * Add first class expander objects.
    * Add params casting for expander.
    * Add simple router and rack router.
    * Add weak equality map to significantly improve performance.
    * Fix Ruby warnings.
    * Improve documentation.
    * Refactor pattern validation, AST transformations.
    * Increase test coverage (from 100%+ to 100%++).
    * Improve JRuby compatibility.
    * Work around bug in 2.0.0-p0.
* **Mustermann 0.1.0** (2013-05-12)
    * More Infos:
      [RubyGems.org](http://rubygems.org/gems/mustermann/versions/0.1.0),
      [RubyDoc.info](http://rubydoc.info/gems/mustermann/0.1.0/frames),
      [GitHub.com](https://github.com/rkh/mustermann/tree/v0.1.0)
    * Add `Pattern#expand` for generating strings from patterns.
    * Add better internal API for working with the AST.
    * Improved documentation.
    * Avoids parsing the path twice when used as Sinatra extension.
    * Better exceptions for unknown pattern types.
    * Better handling of edge cases around extend.
    * More specs to ensure API stability.
    * Largely rework internals of Sinatra, Rails and Template patterns.
* **Mustermann 0.0.1** (2013-04-27)
    * More Infos:
      [RubyGems.org](http://rubygems.org/gems/mustermann/versions/0.0.1),
      [RubyDoc.info](http://rubydoc.info/gems/mustermann/0.0.1/frames),
      [GitHub.com](https://github.com/rkh/mustermann/tree/v0.0.1)
    * Initial Release.

### Upcoming Releases

* **Mustermann 0.4.0** (next release with new features)
    * Add `Pattern#to_proc`.
    * Add `Pattern#|`, `Pattern#&` and `Pattern#^`.
    * Add `Pattern#peek`, `Pattern#peek_size`, `Pattern#peek_match` and `Pattern#peek_params`.
    * Add `Mustermann::StringScanner`.
    * Add `Pattern#to_templates`.
    * Add `|` syntax to `sinatra` templates.
    * Add template style placeholders to `sinatra` templates.
    * Add `cake`, `express`, `flask` and `pyramid` patterns.
    * Allow passing in additional value behavior directly to `Pattern#expand`.
* **Mustermann 1.0.0** (before Sinatra 2.0)
    * First stable release.