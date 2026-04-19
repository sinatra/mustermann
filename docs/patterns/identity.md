# The Identity Pattern

Implemented in the `mustermann` gem. It is the least powerful pattern type, as it doesn't support any special syntax. It is useful if you want to match a fixed string or if you want to implement your own pattern type on top of it.

``` ruby
require 'mustermann'

pattern = Mustermann.new('/foo/bar', type: :identity)
pattern === '/foo/bar' # => true
pattern === '/foo/baz' # => false
pattern.params('/foo/bar') # => {}
```

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

## Examples

| Pattern | String | Params |
|---------|--------|--------|
| `/foo` | `/foo` | `{}` |
| `/foo/bar` | `/foo/bar` | `{}` |
| `/users/42` | `/users/42` | `{}` |
