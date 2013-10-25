# The Amazing Mustermann

[![Build Status](https://travis-ci.org/rkh/mustermann.png?branch=master)](https://travis-ci.org/rkh/mustermann) [![Coverage Status](https://coveralls.io/repos/rkh/mustermann/badge.png?branch=master)](https://coveralls.io/r/rkh/mustermann) [![Code Climate](https://codeclimate.com/github/rkh/mustermann.png)](https://codeclimate.com/github/rkh/mustermann) [![Dependency Status](https://gemnasium.com/rkh/mustermann.png)](https://gemnasium.com/rkh/mustermann) [![Gem Version](https://badge.fury.io/rb/mustermann.png)](http://badge.fury.io/rb/mustermann)

*Make sure you view the correct docs: [latest release](http://rubydoc.info/gems/mustermann/frames), [master](http://rubydoc.info/github/rkh/mustermann/master/frames).*

Welcome to [Mustermann](http://en.wikipedia.org/wiki/List_of_placeholder_names_by_language#German). Mustermann is your personal string matching expert. As an expert in the field of strings and patterns, Mustermann also has no runtime dependencies and is fully covered with specs and documentation.

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
```

Besides being a `Regexp` look-alike, Mustermann also adds a `params` method, that will give you a Sinatra-style hash:

``` ruby
pattern = Mustermann.new('/:prefix/*.*')
pattern.params('/a/b.c') # => { "prefix" => "a", splat => ["b", "c"] }
```

It's generally a good idea to reuse pattern objects, since as much computation as possible is happening during object creation, so that the actual matching or expanding is quite fast.

## Types and Options

You can pass in additional options to take fine grained control over the pattern:

``` ruby
Mustermann.new('/:foo.:bar', capture: :alpha) # :foo and :bar will only match alphabetic characters
```

In fact, you can even completely change the pattern type:

``` ruby
Mustermann.new('/**/*.png', type: :shell)
```

The available types are:

<table>
  <thead>
    <tr>
      <th>Type</th>
      <th>Description</th>
      <th>Example</th>
      <th>Available Options</th>
      <th>Additional Features</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th><a href="#identity"><tt>identity</tt></a></th>
      <td>URI unescaped input string has to match exactly</td>
      <td><tt>/image.png</tt></td>
      <td>
        <a href="#ignore_unknown_options"><tt>ignore_unknown_options</tt></a>,
        <a href="#uri_decode"><tt>uri_decode</tt></a>
      </td>
      <td></td>
    </tr>
    <tr>
      <th><a href="#rails"><tt>rails</tt></a></th>
      <td>Rails style patterns</td>
      <td><tt>/:slug(.:ext)</tt></td>
      <td>
        <a href="#capture"><tt>capture</tt></a>,
        <a href="#except"><tt>except</tt></a>,
        <a href="#greedy"><tt>greedy</tt></a>,
        <a href="#ignore_unknown_options"><tt>ignore_unknown_options</tt></a>,
        <a href="#space_matches_plus"><tt>space_matches_plus</tt></a>,
        <a href="#uri_decode"><tt>uri_decode</tt></a>
      </td>
      <td>
        <a href="#pattern_expanding">Expanding</a>
      </td>
    </tr>
    <tr>
      <th><a href="#regexp"><tt>regexp</tt></a></th>
      <td>Regular expressions as implemented by Ruby</td>
      <td><tt>/(?&lt;slug&gt;.*)</tt></td>
      <td>
        <a href="#ignore_unknown_options"><tt>ignore_unknown_options</tt></a>,
        <a href="#uri_decode"><tt>uri_decode</tt></a>
      </td>
      <td></td>
    </tr>
    <tr>
      <th><a href="#shell"><tt>shell</tt></th>
      <td>Unix style patterns</td>
      <td><tt>/*.{png,jpg}</tt></td>
      <td>
        <a href="#ignore_unknown_options"><tt>ignore_unknown_options</tt></a>,
        <a href="#uri_decode"><tt>uri_decode</tt></a>
      </td>
      <td></td>
    </tr>
    <tr>
      <th><a href="#simple"><tt>simple</tt></a></th>
      <td>Sinatra 1.3 style patterns</td>
      <td><tt>/:slug.:ext</tt></td>
      <td>
        <a href="#greedy"><tt>greedy</tt></a>,
        <a href="#ignore_unknown_options"><tt>ignore_unknown_options</tt></a>,
        <a href="#space_matches_plus"><tt>space_matches_plus</tt></a>,
        <a href="#uri_decode"><tt>uri_decode</tt></a>
      </td>
      <td></td>
    </tr>
    <tr>
      <th><a href="#sinatra"><tt>sinatra</tt></a></th>
      <td>Sinatra 2.0 style patterns (default)</td>
      <td><tt>/:slug(.:ext)?</tt></td>
      <td>
        <a href="#capture"><tt>capture</tt></a>,
        <a href="#except"><tt>except</tt></a>,
        <a href="#greedy"><tt>greedy</tt></a>,
        <a href="#ignore_unknown_options"><tt>ignore_unknown_options</tt></a>,
        <a href="#space_matches_plus"><tt>space_matches_plus</tt></a>,
        <a href="#uri_decode"><tt>uri_decode</tt></a>
      </td>
      <td>
        <a href="#pattern_expanding">Expanding</a>
      </td>
    </tr>
    <tr>
      <th><a href="#template"><tt>template</tt></a></th>
      <td><a href="http://tools.ietf.org/html/rfc6570">URI templates</a></td>
      <td><tt>/dictionary/{term}</tt></td>
      <td>
        <a href="#capture"><tt>capture</tt></a>,
        <a href="#except"><tt>except</tt></a>,
        <a href="#greedy"><tt>greedy</tt></a>,
        <a href="#ignore_unknown_options"><tt>ignore_unknown_options</tt></a>,
        <a href="#space_matches_plus"><tt>space_matches_plus</tt></a>,
        <a href="#uri_decode"><tt>uri_decode</tt></a>
      </td>
      <td>
        <a href="#pattern_expanding">Expanding</a>
      </td>
    </tr>
  </tbody>
</table>

See below for more details.

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

<a name="pattern_expanding"></a>
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
expander = Mustermann::Expander.new
expander << "/users/:user_id"
expander << "/pages/:page_id"

expander.expand(user_id: 15) # => "/users/15"
expander.expand(page_id: 58) # => "/pages/58"
```

You can set pattern options when creating the expander:

``` ruby
expander = Mustermann::Expander.new(type: :template)
expander << "/users/{user_id}"
expander << "/pages/{page_id}"
```

Additionally, it is possible to combine patterns of different types:

``` ruby
expander = Mustermann::Expander.new
expander << Mustermann.new("/users/{user_id}", type: :template)
expander << Mustermann.new("/pages/:page_id",  type: :rails)
```

### Handling Additional Values

The handling of additional values passed in to `expand` can be changed by setting the `additional_values` option:

``` ruby
expander = Mustermann::Expander.new("/:slug", additional_values: :raise)
expander.expand(slug: "foo", value: "bar") # raises Mustermann::ExpandError

expander = Mustermann::Expander.new("/:slug", additional_values: :ignore)
expander.expand(slug: "foo", value: "bar") # => "/foo"

expander = Mustermann::Expander.new("/:slug", additional_values: :append)
expander.expand(slug: "foo", value: "bar") # => "/foo?value=bar"
```

## Duck Typing

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

## Partial Loading and Thread Safety

Pattern objects are generally assumed to be thread-safe. You can easily match strings against the same pattern object concurrently.

Mustermann will only load the pattern implementation you need. For example, `mustermann/rails` is loaded the first time you invoke `Mustermann.new(..., type: :rails)`. This part might not be thread-safe, depending on your Ruby implementation.

In the common use cases, that is Sinatra and similar, patterns are compiled on the main thread during the application load phase, so this is a non-issue there.

To avoid this, you can load the pattern types you need manually:

``` ruby
require 'mustermann/sinatra'
Mustermann::Sinatra.new('/:foo')
```

## Options

### `capture`

Supported by: `rails`, `sinatra`, `template`

**Sinatra**, **URI template** and **Rails** patterns support changing the way named captures work via the `capture` options.

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

### `except`

Supported by: `rails`, `sinatra`, `template`

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

### `greedy`

Supported by: `rails`, `simple`, `sinatra`, `template`. Default value: `true`

**Simple** patterns are greedy, meaning that for the pattern `:foo:bar?`, everything will be captured as `foo`, `bar` will always be `nil`. By setting `greedy` to `false`, `foo` will capture as little as possible (which in this case would only be the first letter), leaving the rest to `bar`.

**Sinatra**, **URI template** and **Rails** patterns are semi-greedy. This means `:foo(.:bar)?` (`:foo(.:bar)` for Rails patterns) will capture everything before the *last* dot as `foo`. For these two pattern types, you can switch into non-greedy mode by setting the `greedy` option to false. In that case `foo` will only capture the part before the *first* dot.

Semi-greedy behavior is not specific to dots, it works with all characters or strings. For instance, `:a(foo:b)` will capture everything before the *last* `foo` as `a`, and `:foo(bar)?` will not capture a `bar` at the end.

``` ruby
pattern = Mustermann.new(':a.:b', greedy: true)
pattern.match('a.b.c.d') # => #<MatchData a:"a.b.c" b:"d">

pattern = Mustermann.new(':a.:b', greedy: false)
pattern.match('a.b.c.d') # => #<MatchData a:"a" b:"b.c.d">
```

### `space_matches_plus`

Supported by: `rails`, `simple`, `sinatra`, `template`. Default value: `true`

**Sinatra**, **Simple**, **URI template** and **Rails** patterns will by default also match a plus sign for a space in the pattern:

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

### `uri_decode`

Supported by all patterns. Default value: `true`

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

### `ignore_unknown_options`

Supported by all patterns. Default value: `false`

If you pass an option in that is not supported by the specific pattern type, Mustermann will raise an `ArgumentError`.
By setting `ignore_unknown_options` to `true`, it will happily ignore the option.

## Pattern Types

### `identity`

Identity patterns are strings that have to match the input exactly.

``` ruby
require 'mustermann'

pattern = Mustermann.new('/:example', type: :identity)
pattern === "/foo.bar"      # => false
pattern === "/:example"     # => true
pattern.params("/foo.bar")  # => nil
pattern.params("/:example") # => {}
```

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

### `rails`

Patterns with the syntax used in Rails route definitions.

``` ruby
require 'mustermann'

pattern = Mustermann.new('/:example', type: :rails)
pattern === "/foo.bar"     # => true
pattern === "/foo/bar"     # => false
pattern.params("/foo.bar") # => { "example" => "foo.bar" }
pattern.params("/foo/bar") # => nil

pattern = Mustermann.new('/:example(/:optional)', type: :rails)
pattern === "/foo.bar"     # => true
pattern === "/foo/bar"     # => true
pattern.params("/foo.bar") # => { "example" => "foo.bar", "optional" => nil   }
pattern.params("/foo/bar") # => { "example" => "foo",     "optional" => "bar" }

pattern = Mustermann.new('/*example', type: :rails)
pattern === "/foo.bar"     # => true
pattern === "/foo/bar"     # => true
pattern.params("/foo.bar") # => { "example" => "foo.bar" }
pattern.params("/foo/bar") # => { "example" => "foo/bar" }
```

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

### `regexp`

Regular expression patterns, as used implemented by Ruby. Do not include characters for matching beginning or end of string/line.
This pattern type is also known as `regular` and the pattern class is `Mustermann::Regular` (located in `mustermann/regular`).

``` ruby
require 'mustermann'

pattern = Mustermann.new('/(?<example>.*)', type: :regexp)
pattern === "/foo.bar"     # => true
pattern === "/foo/bar"     # => true
pattern.params("/foo.bar") # => { "example" => "foo.bar" }
pattern.params("/foo/bar") # => { "example" => "foo/bar" }
```

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

It is also possible to turn a proper Regexp instance into a pattern object by passing it to `Mustermann.new`:

``` ruby
require 'mustermann'
Mustermann.new(/(?<example>.*)/).params("input") # => { "example" => "input" }
```

### `shell`

Shell patterns, as used in Bash or with `Dir.glob`.

``` ruby
require 'mustermann'

pattern = Mustermann.new('/*', type: :shell)
pattern === "/foo.bar" # => true
pattern === "/foo/bar" # => false

pattern = Mustermann.new('/**/*', type: :shell)
pattern === "/foo.bar" # => true
pattern === "/foo/bar" # => true

pattern = Mustermann.new('/{foo,bar}', type: :shell)
pattern === "/foo"     # => true
pattern === "/bar"     # => true
pattern === "/baz"     # => false
```

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

### `simple`

Patterns as used by Sinatra 1.3. Useful for porting an application that relies on this behavior to a later Sinatra version and to make sure [Sinatra 2.0](#sinatra) patterns do not decrease performance. Simple patterns internally use the same code older Sinatra versions used for compiling the pattern. Error messages for broken patterns will therefore not be as informative as for other pattern implementations.

``` ruby
require 'mustermann'

pattern = Mustermann.new('/:example', type: :simple)
pattern === "/foo.bar"     # => true
pattern === "/foo/bar"     # => false
pattern.params("/foo.bar") # => { "example" => "foo.bar" }
pattern.params("/foo/bar") # => nil

pattern = Mustermann.new('/:example/?:optional?', type: :simple)
pattern === "/foo.bar"     # => true
pattern === "/foo/bar"     # => true
pattern.params("/foo.bar") # => { "example" => "foo.bar", "optional" => nil   }
pattern.params("/foo/bar") # => { "example" => "foo",     "optional" => "bar" }

pattern = Mustermann.new('/*', type: :simple)
pattern === "/foo.bar"     # => true
pattern === "/foo/bar"     # => true
pattern.params("/foo.bar") # => { "splat" => ["foo.bar"] }
pattern.params("/foo/bar") # => { "splat" => ["foo/bar"] }
```

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

### `sinatra`

Sinatra 2.0 style patterns. The default used by Mustermann.

``` ruby
require 'mustermann'

pattern = Mustermann.new('/:example')
pattern === "/foo.bar"     # => true
pattern === "/foo/bar"     # => false
pattern.params("/foo.bar") # => { "example" => "foo.bar" }
pattern.params("/foo/bar") # => nil

pattern = Mustermann.new('/\:example')
pattern === "/foo.bar"      # => false
pattern === "/:example"     # => true
pattern.params("/foo.bar")  # => nil
pattern.params("/:example") # => {}

pattern = Mustermann.new('/:example(/:optional)?')
pattern === "/foo.bar"     # => true
pattern === "/foo/bar"     # => true
pattern.params("/foo.bar") # => { "example" => "foo.bar", "optional" => nil   }
pattern.params("/foo/bar") # => { "example" => "foo",     "optional" => "bar" }

pattern = Mustermann.new('/*')
pattern === "/foo.bar"     # => true
pattern === "/foo/bar"     # => true
pattern.params("/foo.bar") # => { "splat" => ["foo.bar"] }
pattern.params("/foo/bar") # => { "splat" => ["foo/bar"] }

pattern = Mustermann.new('/*example')
pattern === "/foo.bar"     # => true
pattern === "/foo/bar"     # => true
pattern.params("/foo.bar") # => { "example" => "foo.bar" }
pattern.params("/foo/bar") # => { "example" => "foo/bar" }
```

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
      <td><b>*</b></td>
      <td>
        Captures anything in a non-greedy fashion. Capture is named splat.
        It is always an array of captures, as you can use <tt>*</tt> more than once in a pattern.
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
      <td><i>x</i><b>?</b></td>
      <td>Makes <i>x</i> optional. For instance <tt>(foo)?</tt> matches <tt>foo</tt> or an empty string.</td>
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

### `template`

Parses fully expanded URI templates as specified by [RFC 6570](http://tools.ietf.org/html/rfc6570).

Note that it differs from URI templates in that it takes the unescaped version of special character instead of the escaped version.

``` ruby
require 'mustermann'

pattern = Mustermann.new('/{example}', type: :template)
pattern === "/foo.bar"     # => true
pattern === "/foo/bar"     # => false
pattern.params("/foo.bar") # => { "example" => "foo.bar" }
pattern.params("/foo/bar") # => nil

pattern = Mustermann.new("{/segments*}/{page}{.ext,cmpr:2}", type: :template)
pattern.params("/a/b/c.tar.gz") # => {"segments"=>["a","b"], "page"=>"c", "ext"=>"tar", "cmpr"=>"gz"}
```

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

If you reuse the exact same templates and expose them via an external API meant for expansion,
you should set `uri_decode` to `false` in order to conform with the specification.

If you are looking for an alternative implementation that also supports expanding, check out [addressable](http://addressable.rubyforge.org/).

## Mapper

You can use a mapper to transform strings according to two or more mappings:

``` ruby
require 'mustermann/mapper'

mapper = Mustermann::Mapper.new("/:page(.:format)?" => ["/:page/view.:format", "/:page/view.html"])
mapper['/foo']     # => "/foo/view.html"
mapper['/foo.xml'] # => "/foo/view.xml"
mapper['/foo/bar'] # => "/foo/bar"
```

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

## Requirements

Mustermann has no dependencies besides a Ruby 2.0 compatible Ruby implementation.

It is known to work on **MRI 2.0** and **MRI trunk**.

**JRuby** is not yet fully supported. It is possible to run large parts of Mustermann by passing in `--2.0 -X-C` starting from JRuby 1.7.4. See [issue #2](https://github.com/rkh/mustermann/issues/2) for up to date information.

**Rubinius** is not yet able to parse the Mustermann source code. See [issue #14](https://github.com/rkh/mustermann/issues/14) for up to date information.

## Release History

Mustermann follows [Semantic Versioning 2.0](http://semver.org/). Anything documented in the README or via YARD and not declared private is part of the public API.

### Stable Releases

There have been no stable releases yet. The code base is considered solid but I don't know of anyone using it in production yet.
As there has been no stable release yet, the API might still change, though I consider this unlikely.

### Development Releases

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

* **Mustermann 0.3.0** (next release with new features)
    * Add `regexp` pattern.
    * Add named splats to Sinatra patterns.
    * Add `Mustermann::Mapper`.
    * Improve duck typing support.
    * Improve documentation.
* **Mustermann 1.0.0** (before Sinatra 2.0)
    * First stable release.
