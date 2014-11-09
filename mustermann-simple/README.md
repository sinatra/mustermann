# Simple Syntax for Mustermann

This gem implements the `simple` pattern type for Mustermann. It is compatible with [Sinatra](http://www.sinatrarb.com/) (1.x), [Scalatra](http://www.scalatra.org/) and [Dancer](http://perldancer.org/).

## Overview

**Supported options:**
`greedy`, `space_matches_plus`, `uri_decode` and `ignore_unknown_options`.

This is useful for porting an application that relies on this behavior to a later Sinatra version and to make sure Sinatra 2.0 patterns do not decrease performance. Simple patterns internally use the same code older Sinatra versions used for compiling the pattern. Error messages for broken patterns will therefore not be as informative as for other pattern implementations.

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

## Syntax

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