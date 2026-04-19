# `sinatra`

The `sinatra` pattern type is implemented by Mustermann itself. Moreover, it is the default pattern type, chosen by Mustermann if the `type` option is not specified.

**Supported options:**
[`capture`](#-available-options--capture),
[`except`](#-available-options--except),
[`greedy`](#-available-options--greedy),
[`space_matches_plus`](#-available-options--space_matches_plus),
[`uri_decode`](#-available-options--uri_decode),
[`ignore_unknown_options`](#-available-options--ignore_unknown_options).

# Overview

``` ruby
require 'mustermann'

pattern = Mustermann.new('/:name')
pattern === '/alice'      # => true
pattern === '/alice/bob'  # => false
pattern.params('/alice')  # => { "name" => "alice" }

pattern = Mustermann.new('/:foo/:bar')
pattern.params('/hello/world') # => { "foo" => "hello", "bar" => "world" }

pattern = Mustermann.new('/*')
pattern.params('/a/b/c') # => { "splat" => ["a/b/c"] }
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
      <td><b>:</b><i>name</i> <i><b>or</b></i> <b>&#123;</b><i>name</i><b>&#125;</b></td>
      <td>
        Captures anything but a forward slash in a semi-greedy fashion. Capture is named <i>name</i>.
        Capture behavior can be modified with <tt>capture</tt> and <tt>greedy</tt> option.
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
      <td><i>expression</i><b>|</b><i>expression</i><b>|</b><i>...</i></td>
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

## Examples

| Pattern | String | Params |
|---------|--------|--------|
| `/foo` | `/foo` | `{}` |
| `/:name` | `/alice` | `{"name" => "alice"}` |
| `/:foo/:bar` | `/hello/world` | `{"foo" => "hello", "bar" => "world"}` |
| `/*` | `/a/b/c` | `{"splat" => ["a/b/c"]}` |
| `/:name/*` | `/alice/some/path` | `{"name" => "alice", "splat" => ["some/path"]}` |
| `/:foo(/:bar)` | `/hello` | `{"foo" => "hello", "bar" => nil}` |
