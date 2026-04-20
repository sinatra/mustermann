# Hybrid Patterns

The `hybrid` pattern type, implemented by the `mustermann` gem, tries to bridge the gap between `sinatra` and `rails`, by being largely compatible with both, while still supporting all features provided by Mustermann.

Hybrid patterns are Rails- and Sinatra-like patterns, as well as compatible with simple URI templates.

``` ruby
require 'mustermann'

# Groups without | are implicitly optional (Rails style)
pattern = Mustermann.new('/scope(/nested)', type: :hybrid)
pattern === '/scope/nested' # => true
pattern === '/scope'        # => true
pattern === '/scope/'       # => false

# Groups with | are not implicitly optional
pattern = Mustermann.new('/scope/(a|b)', type: :hybrid)
pattern === '/scope/a' # => true
pattern === '/scope/b' # => true
pattern === '/scope/'  # => false

# Use ? to make groups with | optional
pattern = Mustermann.new('/scope/(a|b)?', type: :hybrid)
pattern === '/scope/'  # => true

# Named captures, splats and URI template placeholders work as in sinatra
pattern = Mustermann.new('/:controller(/:action(/:id))', type: :hybrid)
pattern.params('/posts')      # => { "controller" => "posts" }
pattern.params('/posts/show') # => { "controller" => "posts", "action" => "show" }

pattern = Mustermann.new('/*prefix/:name', type: :hybrid)
pattern.params('/a/b/c') # => { "prefix" => "a/b", "name" => "c" }
```

**Supported options:**
[`capture`](#-available-options--capture),
[`except`](#-available-options--except),
[`greedy`](#-available-options--greedy),
[`space_matches_plus`](#-available-options--space_matches_plus),
[`uri_decode`](#-available-options--uri_decode),
[`ignore_unknown_options`](#-available-options--ignore_unknown_options).

## Compatibility notes

* **Rails**: All syntax elements are supported. However, a group that includes a pipe operator will not be marked optional by default.
  So `/scope/(a|b)` will match both `/scope/a` and `/scope/b`, but not `/scope/`. Hybrid also supports additional syntax elements not supported by Rails, like an unnamed splat (`/scope/*`), or a question mark for marking a segment as optional (`/scope/(a|b)?`).
* **Sinatra**: All syntax elements are supported, but a group without a pipe operator will be marked optional, even if it isn't followed by a question mark.
  So `/scope(/nested)` will match both `/scope/nested` and `/scope`.
* **URI Templates**: Only simple placeholders (`/scope/{tenant_id}`), non-standard pipes (`/scope/{tenant_id|scope_id}`) and splats (`/scope/{+segments}`) are supported.

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
        Enclosed <i>expression</i> is an implicitly optional group, equivalent to
        <tt>(expression)?</tt>. This matches Rails behavior.
        To create a non-optional group, use a pipe operator inside: <tt>(a|b)</tt>.
      </td>
    </tr>
    <tr>
      <td><b>(</b><i>expression</i><b>|</b><i>expression</i><b>|</b>...<b>)</b></td>
      <td>
        Will match anything matching the nested expressions. May contain any other syntax element,
        including captures. A group containing a pipe operator is <em>not</em> implicitly optional;
        use a trailing <tt>?</tt> to make it optional.
      </td>
    </tr>
    <tr>
      <td><i>x</i><b>?</b></td>
      <td>Makes <i>x</i> optional. For groups containing <tt>|</tt>, this is the only way to make them optional.</td>
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
| `/scope(/nested)` | `/scope` | `{}` |
| `/:file(.:ext)` | `/pony` | `{"file" => "pony", "ext" => nil}` |
| `/:file(.:ext)` | `/pony.jpg` | `{"file" => "pony", "ext" => "jpg"}` |
| `/(a\|b)` | `/a` | `{}` |
| `/(a\|b)?` | `/` | `{}` |
| `/:controller(/:action(/:id))` | `/posts/show` | `{"controller" => "posts", "action" => "show", "id" => nil}` |
