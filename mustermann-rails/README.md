# Rails Syntax for Mustermann

This gem implements the `rails` pattern type for Mustermann. It is compatible with [Ruby on Rails](http://rubyonrails.org/), [Journey](https://github.com/rails/journey), the [http_router gem](https://github.com/joshbuddy/http_router), [Lotus](http://lotusrb.org/) and [Scalatra](http://www.scalatra.org/) (if [configured](http://www.scalatra.org/2.3/guides/http/routes.html#toc_248))</td>

## Overview

**Supported options:**
`capture`, `except`, `greedy`, `space_matches_plus`, `uri_decode`, and `ignore_unknown_options`.

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