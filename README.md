# Mustermann [![Build Status](https://travis-ci.org/rkh/mustermann.png?branch=master)](https://travis-ci.org/rkh/mustermann) [![Coverage Status](https://coveralls.io/repos/rkh/mustermann/badge.png?branch=master)](https://coveralls.io/r/rkh/mustermann) [![Code Climate](https://codeclimate.com/github/rkh/mustermann.png)](https://codeclimate.com/github/rkh/mustermann) [![Dependency Status](https://gemnasium.com/rkh/mustermann.png)](https://gemnasium.com/rkh/mustermann) [![Gem Version](https://badge.fury.io/rb/mustermann.png)](http://badge.fury.io/rb/mustermann)

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

It's generally a good idea to reuse pattern objects, since as much computation as possible is happening during object creation, so that the actual matching is quite fast.

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
    </tr>
    <tr>
      <th><a href="#shell"><tt>shell</tt></th>
      <td>Unix style patterns</td>
      <td><tt>/*.{png,jpg}</tt></td>
      <td>
        <a href="#ignore_unknown_options"><tt>ignore_unknown_options</tt></a>,
        <a href="#uri_decode"><tt>uri_decode</tt></a>
      </td>
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

Patterns that are no real patterns, just string matching.

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

### `shell`

Shell patterns, as used in Bash or with `Dir.glob`.

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

Patterns as used by Sinatra 1.3. Useful for porting an application that relies on this behavior to a later Sinatra version and to make sure [Sinatra 2.0](#sinatra) patterns do not decrease performance.

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

``` ruby
pattern = Mustermann.new("{/segments*}/{page}{.ext,cmpr:2}", type: :template)
pattern.params("/a/b/c.tar.gz") # => {"segments"=>["a","b"], "page"=>"c", "ext"=>"tar", "cmpr"=>"gz"}
```

Please keep the following in mind:

> "Some URI Templates can be used in reverse for the purpose of variable matching: comparing the template to a fully formed URI in order to extract the variable parts from that URI and assign them to the named variables.  Variable matching only works well if the template expressions are delimited by the beginning or end of the URI or by characters that cannot be part of the expansion, such as reserved characters surrounding a simple string expression.  In general, regular expression languages are better suited for variable matching."
> &mdash; *RFC 6570, Sec 1.5: "Limitations"*

If you reuse the exact same templates and expose them via an external API meant for expansion,
you should set `uri_decode` to `false` in order to conform with the specification.

If you are looking for an alternative implementation that also supports expanding, check out [addressable](http://addressable.rubyforge.org/).

## Versioning

Mustermann follows [Semantic Versioning](http://semver.org/).
