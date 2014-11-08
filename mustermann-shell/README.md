# Shell Syntax for Mustermann

This gem implements the `rails` pattern type for Mustermann. It is compatible with common Unix shells (like bash or zsh).

## Overview

**Supported options:** `uri_decode` and `ignore_unknown_options`.

**External documentation:** [Ruby's fnmatch](http://www.ruby-doc.org/core-2.1.4/File.html#method-c-fnmatch), [Wikipedia: Glob (programming)](http://en.wikipedia.org/wiki/Glob_(programming))

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
