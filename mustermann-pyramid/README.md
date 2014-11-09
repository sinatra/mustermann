# Pyramid Syntax for Mustermann

This gem implements the `pyramid` pattern type for Mustermann. It is compatible with [Pyramid](http://www.pylonsproject.org/projects/pyramid/about) and [Pylons](http://www.pylonsproject.org/projects/pylons-framework/about).

## Overview

**Supported options:**
`capture`, `except`, `greedy`, `space_matches_plus`, `uri_decode` and `ignore_unknown_options`

**External Documentation:** [Pylons Framework: URL Configuration](http://docs.pylonsproject.org/projects/pylons-webframework/en/latest/configuration.html#url-config), [Pylons Book: Routes in Detail](http://pylonsbook.com/en/1.0/urls-routing-and-dispatch.html#routes-in-detail), [Pyramid: Route Pattern Syntax](http://docs.pylonsproject.org/projects/pyramid/en/1.5-branch/narr/urldispatch.html#route-pattern-syntax)

``` ruby
require 'mustermann/pyramid'

Mustermann.new('/{prefix}/*suffix', type: :pyramid).params('/a/b/c') # => { prefix: 'a', suffix: ['b', 'c'] }

pattern = Mustermann.new('/{name}', type: :pyramid)

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
      <td><b>&#123;</b><i>name</i><b>&#125;</b></td>
      <td>
        Captures anything but a forward slash in a semi-greedy fashion. Capture is named <i>name</i>.
        Capture behavior can be modified with <tt>capture</tt> and <tt>greedy</tt> option.
      </td>
    </tr>
    <tr>
      <td><b>&#123;</b><i>name</i><b>:</b><i>regexp</i><b>&#125;</b></td>
      <td>
        Captures anything matching the <i>regexp</i> regular expression. Capture is named <i>name</i>.
        Capture behavior can be modified with <tt>capture</tt>.
      </td>
    </tr>
    <tr>
      <td><b>*</b><i>name</i></td>
      <td>
        Captures anything in a non-greedy fashion. Capture is named <i>name</i>.
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
