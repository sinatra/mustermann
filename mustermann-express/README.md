# Express Syntax for Mustermann

This gem implements the `express` pattern type for Mustermann. It is compatible with [Express](http://expressjs.com/) and [pillar.js](https://pillarjs.github.io/).

## Overview

**Supported options:**
`capture`, `except`, `greedy`, `space_matches_plus`, `uri_decode`, and `ignore_unknown_options`.

**External documentation:**
[path-to-regexp](https://github.com/pillarjs/path-to-regexp#path-to-regexp),
[live demo](http://forbeslindesay.github.io/express-route-tester/)

Express patterns feature named captures (with repetition support via suffixes) that start with a colon and can have an optional regular expression constraint or unnamed captures that require a constraint.

``` ruby
require 'mustermann/express'

Mustermann.new('/:name/:rest+', type: :express).params('/a/b/c') # => { name: 'a', rest: 'b/c' }

pattern = Mustermann.new('/:name', type: :express)

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
      <td><b>:</b><i>name</i><b>+</b></td>
      <td>
        Captures one or more segments (with segments being separated by forward slashes).
        Capture is named <i>name</i>.
        Capture behavior can be modified with <tt>capture</tt> option.
      </td>
    </tr>
    <tr>
      <td><b>:</b><i>name</i><b>*</b></td>
      <td>
        Captures zero or more segments (with segments being separated by forward slashes).
        Capture is named <i>name</i>.
        Capture behavior can be modified with <tt>capture</tt> option.
      </td>
    </tr>
    <tr>
      <td><b>:</b><i>name</i><b>?</b></td>
      <td>
        Captures anything but a forward slash in a semi-greedy fashion. Capture is named <i>name</i>.
        Also matches an empty string.
        Capture behavior can be modified with <tt>capture</tt> and <tt>greedy</tt> option.
      </td>
    </tr>
    <tr>
      <td><b>:</b><i>name</i><b>(</b><i>regexp</i><b>)</b></td>
      <td>
        Captures anything matching the <i>regexp</i> regular expression. Capture is named <i>name</i>.
        Capture behavior can be modified with <tt>capture</tt>.
      </td>
    </tr>
    <tr>
      <td><b>(</b><i>regexp</i><b>)</b></td>
      <td>
        Captures anything matching the <i>regexp</i> regular expression. Capture is named splat.
        Capture behavior can be modified with <tt>capture</tt>.
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