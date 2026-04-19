# The *Regex* Pattern

The `regexp` pattern type is implemented in the `mustermann` gem. It allows you to use regular expressions as patterns.

``` ruby
require 'mustermann'

pattern = Mustermann.new('/\d+', type: :regexp)
pattern === '/123' # => true
pattern === '/abc' # => false

pattern = Mustermann.new('/(?<year>\d{4})/(?<month>\d{2})', type: :regexp)
pattern.params('/2024/01') # => { "year" => "2024", "month" => "01" }
```

**Supported options:**
[`uri_decode`](#-available-options--uri_decode),
[`ignore_unknown_options`](#-available-options--ignore_unknown_options), `check_anchors`.

The pattern string (or actual Regexp instance) should not contain anchors (`^` outside of square brackets, `$`, `\A`, `\z`, or `\Z`).
Anchors will be injected where necessary by Mustermann.

By default, Mustermann will raise a `Mustermann::CompileError` if an anchor is encountered.
If you still want it to contain anchors at your own risk, set the `check_anchors` option to `false`.

Using anchors will break [peeking](#-peeking) and [concatenation](#-concatenation).

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

## Examples

| Pattern | String | Params |
|---------|--------|--------|
| `/foo` | `/foo` | `{}` |
| `/\d+` | `/123` | `{}` |
| `/(?<name>\w+)` | `/alice` | `{"name" => "alice"}` |
| `/(?<year>\d{4})/(?<month>\d{2})` | `/2024/01` | `{"year" => "2024", "month" => "01"}` |
