# URI Template Syntax for Mustermann

This gem implements the `uri-template` (or `template`) pattern type for Mustermann. It is compatible with [RFC 6570](https://tools.ietf.org/html/rfc6570) (level 4), [JSON API](http://jsonapi.org/), [JSON Home Documents](http://tools.ietf.org/html/draft-nottingham-json-home-02) and [many more](https://code.google.com/p/uri-templates/wiki/Implementations)

## Overview

**Supported options:**
`capture`, `except`, `greedy`, `space_matches_plus`, `uri_decode`, and `ignore_unknown_options`.

Please keep the following in mind:

> "Some URI Templates can be used in reverse for the purpose of variable matching: comparing the template to a fully formed URI in order to extract the variable parts from that URI and assign them to the named variables.  Variable matching only works well if the template expressions are delimited by the beginning or end of the URI or by characters that cannot be part of the expansion, such as reserved characters surrounding a simple string expression.  In general, regular expression languages are better suited for variable matching."
> &mdash; *RFC 6570, Sec 1.5: "Limitations"*

``` ruby
require 'mustermann'

pattern = Mustermann.new('/{example}', type: :template)
pattern === "/foo.bar"     # => true
pattern === "/foo/bar"     # => false
pattern.params("/foo.bar") # => { "example" => "foo.bar" }
pattern.params("/foo/bar") # => nil

pattern = Mustermann.new("{/segments*}/{page}{.ext,cmpr:2}", type: :template)
pattern.params("/a/b/c.tar.gz") # => {"segments"=>["a","b"], "page"=>"c", "ext"=>"tar", "cmpr"=>"gz"}
```

## Generating URI Templates

You do not need to use URI templates (and this gem) if all you want is reusing them for hypermedia links. Most other pattern types support generating these (via `#to_pattern`):

``` ruby
require 'mustermann'

Mustermann.new('/:name').to_templates # => ['/{name}']
```

Moreover, Mustermann's default pattern type implements a subset of URI templates (`{capture}` and `{+capture}`) and can therefore also be used for simple templates/

``` ruby
require 'mustermann'

Mustermann.new('/{name}').expand(name: "example") # => "/example"
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
      <td><b>&#123;</b><i>o</i> <i>var</i> <i>m</i><b>,</b> <i>var</i> <i>m</i><b>,</b> ...<b>&#125;</b></td>
      <td>
        Captures expansion.
        Operator <i>o</i>: <code>+ # . / ; ? &amp;</tt> or none.
        Modifier <i>m</i>: <code>:num *</tt> or none.
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

The operators `+` and `#` will always match non-greedy, whereas all other operators match semi-greedy by default.
All modifiers and operators are supported. However, it does not parse lists as single values without the *explode* modifier (aka *star*).
Parametric operators (`;`, `?` and `&`) currently only match parameters in given order.

Note that it differs from URI templates in that it takes the unescaped version of special character instead of the escaped version.

If you reuse the exact same templates and expose them via an external API meant for expansion,
you should set `uri_decode` to `false` in order to conform with the specification.
