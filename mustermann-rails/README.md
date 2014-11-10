# Rails Syntax for Mustermann

This gem implements the `rails` pattern type for Mustermann. It is compatible with [Ruby on Rails](http://rubyonrails.org/), [Journey](https://github.com/rails/journey), the [http_router gem](https://github.com/joshbuddy/http_router), [Lotus](http://lotusrb.org/) and [Scalatra](http://www.scalatra.org/) (if [configured](http://www.scalatra.org/2.3/guides/http/routes.html#toc_248))</td>

## Overview

**Supported options:**
`capture`, `except`, `greedy`, `space_matches_plus`, `uri_decode`, `version`, and `ignore_unknown_options`.

**External documentation:**
[Ruby on Rails Guides: Routing](http://guides.rubyonrails.org/routing.html).

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

## Rails Compatibility

Rails syntax changed over time. You can target different Ruby on Rails versions by setting the `version` option to the desired Rails version.

The default is `4.2`. Versions prior to `2.3` are not supported.

``` ruby
require 'mustermann'
Mustermann.new('/', type: :rails, version: "2.3")
Mustermann.new('/', type: :rails, version: "3.0.0")

require 'rails'
Mustermann.new('/', type: :rails, version: Rails::VERSION::STRING)
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
        Captures anything but a forward slash in a semi-greedy fashion. Capture is named <i>name</i>.
        Capture behavior can be modified with tt>capture</tt> and <tt>greedy</tt> option.
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
      <td>Enclosed <i>expression</i> is optional. Not available in 2.3 compatibility mode.</td>
    </tr>
    <tr>
      <td><b>/</b></td>
      <td>
        Matches forward slash. Does not match URI encoded version of forward slash.
      </td>
    </tr>
    <tr>
      <td><b>\</b><i>x</i></td>
      <td>
        In 3.x compatibility mode and starting with 4.2:
        Matches <i>x</i> or URI encoded version of <i>x</i>. For instance <tt>\*</tt> matches <tt>*</tt>.<br>
        In 4.0 or 4.1 compatibility mode:
        <b>\</b> is ignored, <i>x</i> is parsed normally.<br>
      </td>
    </tr>
    <tr>
      <td><b>|</b></td>
      <td>
        Starting with 3.2 compatibility mode, this will raise a `Mustermann::ParseError`. While Ruby on Rails happily parses this character, it will result in broken routes due to a buggy implementation.
      </td>
    </tr>
    <tr>
      <td><i>any other character</i></td>
      <td>Matches exactly that character or a URI encoded version of it.</td>
    </tr>
  </tbody>
</table>