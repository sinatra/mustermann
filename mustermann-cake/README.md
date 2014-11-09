# CakePHP Syntax for Mustermann

This gem implements the `cake` pattern type for Mustermann. It is compatible with [CakePHP](http://cakephp.org/) 2.x and 3.x.

## Overview

**Supported options:**
`capture`, `except`, `greedy`, `space_matches_plus`, `uri_decode`, and `ignore_unknown_options`.

**External documentation:**
[CakePHP 2.0 Routing](http://book.cakephp.org/2.0/en/development/routing.html),
[CakePHP 3.0 Routing](http://book.cakephp.org/3.0/en/development/routing.html)

CakePHP patterns feature captures and unnamed splats. Captures are prefixed with a colon and splats are either a single asterisk (parsing segments into an array) or a double asterisk (parsing segments as a single string).

``` ruby
require 'mustermann/cake'

Mustermann.new('/:name/*',  type: :cake).params('/a/b/c') # => { name: 'a', splat: ['b', 'c'] }
Mustermann.new('/:name/**', type: :cake).params('/a/b/c') # => { name: 'a', splat: 'b/c' }

pattern = Mustermann.new('/:name')

pattern.respond_to? :expand # => true
pattern.expand(name: 'foo') # => '/foo'

pattern.respond_to? :to_templates # => true
pattern.to_templates              # => ['/{name}']
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
        Capture behavior can be modified with <tt>capture</tt> and <tt>greedy</tt> option.
      </td>
    </tr>
    <tr>
      <td><b>*</b></td>
      <td>
        Captures anything in a non-greedy fashion. Capture is named splat.
        It is always an array of captures, as you can use it more than once in a pattern.
      </td>
    </tr>
    <tr>
      <td><b>**</b></td>
      <td>
        Captures anything in a non-greedy fashion. Capture is named splat.
        It is always an array of captures, as you can use it more than once in a pattern.
        The value matching a single <tt>**</tt> will be split at slashes when parsed into <tt>params</tt>.
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
