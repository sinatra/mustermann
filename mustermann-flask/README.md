# Flask Syntax for Mustermann

This gem implements the `flask` pattern type for Mustermann. It is compatible with [Flask](http://flask.pocoo.org/) and [Werkzeug](http://werkzeug.pocoo.org/).

## Overview

**Supported options:**
`capture`, `except`, `greedy`, `space_matches_plus`, `uri_decode`, `converters` and `ignore_unknown_options`

**External documentation:**
[Werkzeug: URL Routing](http://werkzeug.pocoo.org/docs/0.9/routing/)

``` ruby
require 'mustermann/flask'

Mustermann.new('/<prefix>/<path:page>', type: :flask).params('/a/b/c') # => { prefix: 'a', page: 'b/c' }

pattern = Mustermann.new('/<name>', type: :flask)

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
      <td><b>&lt;</b><i>name</i><b>&gt;</b></td>
      <td>
        Captures anything but a forward slash in a semi-greedy fashion. Capture is named <i>name</i>.
        Capture behavior can be modified with <tt>capture</tt> and <tt>greedy</tt> option.
      </td>
    </tr>
    <tr>
      <td><b>&lt;</b><i>converter</i><b>:</b><i>name</i><b>&gt;</b></td>
      <td>
        Captures depending on the converter constraint. Capture is named <i>name</i>.
        Capture behavior can be modified with <tt>capture</tt> and <tt>greedy</tt> option.
        See below.
      </td>
    </tr>
    <tr>
      <td><b>&lt;</b><i>converter</i><b>(</b><i>arguments</i><b>):</b><i>name</i><b>&gt;</b></td>
      <td>
        Captures depending on the converter constraint. Capture is named <i>name</i>.
        Capture behavior can be modified with <tt>capture</tt> and <tt>greedy</tt> option.
        Arguments are separated by comma. An argument can be a simple string, a string enclosed
        in single or double quotes, or a key value pair (keys and values being separated by an
        equal sign). See below.
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

## Converters

### Builtin Converters

#### `string`

Possible arguments: `minlength`, `maxlength`, `length`

Captures anything but a forward slash in a semi-greedy fashion.
Capture behavior can be modified with <tt>capture</tt> and <tt>greedy</tt> option.

This is also the default converter.

Examples:

```
<name>
<string:name>
<string(minlength=3,maxlength=10):slug>
<string(length=10):slug>
```

#### `int`

Possible arguments: `min`, `max`, `fixed_digits`

Captures digits.
Captured value will be converted to an Integer.

Examples:

```
<int:id>
<int(min=1,max=5):page>
<int(fixed_digits=16):uuid>
```

#### `float`

Possible arguments: `min`, `max`

Captures digits with a dot.
Captured value will be converted to an Float.

Examples:

```
<float:precision>
<float(min=0,max=1):precision>
```

#### `path`

Captures anything in a non-greedy fashion.

Example:

```
<path:rest>
```

#### `any`

Possible arguments: List of accepted strings.

Captures anything that matches one of the arguments exactly.

Example:

```
<any(home,search,contact):page>
```

### Custom Converters

[Flask patterns](#-pattern-details-flask) support registering custom converters.

A converter object may implement any of the following methods:

* `convert`: Should return a block converting a string value to whatever value should end up in the `params` hash.
* `constraint`: Should return a regular expression limiting which input string will match the capture.
* `new`: Returns an object that may respond to `convert` and/or `constraint` as described above. Any arguments used for the converter inside the pattern will be passed to `new`.

``` ruby
require 'mustermann/flask'

SimpleConverter = Struct.new(:constraint, :convert)
id_converter    = SimpleConverter.new(/\d/, -> s { s.to_i })

class NumConverter
  def initialize(base: 10)
    @base = Integer(base)
  end

  def convert
    -> s { s.to_i(@base) }
  end

  def constraint
    @base > 10 ? /[\da-#{(@base-1).to_s(@base)}]/ : /[0-#{@base-1}]/
  end
end

pattern = Mustermann.new('/<id:id>/<num(base=8):oct>/<num(base=16):hex>',
  type: :flask, converters: { id: id_converter, num: NumConverter})

pattern.params('/10/12/f1') # => {"id"=>10, "oct"=>10, "hex"=>241}
```

### Global Converters

It is also possible to register a converter for all flask patterns, using `register_converter`:

``` ruby
Mustermann::Flask.register_converter(:id,  id_converter)
Mustermann::Flask.register_converter(:num, NumConverter)

pattern = Mustermann.new('/<id:id>/<num(base=8):oct>/<num(base=16):hex>', type: :flask)
pattern.params('/10/12/f1') # => {"id"=>10, "oct"=>10, "hex"=>241}
```

There is a handy syntax for quickly creating new converter classes: When you pass a block instead of a converter object, it will yield a generic converter with setters and getters for `convert` and `constraint`, and any arguments passed to the converter.

``` ruby
require 'mustermann/flask'

Mustermann::Flask.register_converter(:id) do |converter|
  converter.constraint = /\d/
  converter.convert    = -> s { s.to_i }
end

Mustermann::Flask.register_converter(:num) do |converter, base: 10|
  converter.constraint = base > 10 ? /[\da-#{(@base-1).to_s(base)}]/ : /[0-#{base-1}]/
  converter.convert    = -> s { s.to_i(base) }
end

pattern = Mustermann.new('/<id:id>/<num(base=8):oct>/<num(base=16):hex>', type: :flask)
pattern.params('/10/12/f1') # => {"id"=>10, "oct"=>10, "hex"=>241}
```

### Subclassing

Registering global converters will make these available for all Flask patterns. It might even override already registered converters. This global state might break unrelated code.

It is therefore recommended that, if you don't want to pass in the converters option for every pattern, you create your own subclass of `Mustermann::Flask`.

``` ruby
require 'mustermann/flask'

MyFlask = Class.new(Mustermann::Flask)

MyFlask.register_converter(:id) do |converter|
  converter.constraint = /\d/
  converter.convert    = -> s { s.to_i }
end

MyFlask.register_converter(:num) do |converter, base: 10|
  converter.constraint = base > 10 ? /[\da-#{(@base-1).to_s(base)}]/ : /[0-#{base-1}]/
  converter.convert    = -> s { s.to_i(base) }
end

pattern = MyFlask.new('/<id:id>/<num(base=8):oct>/<num(base=16):hex>')
pattern.params('/10/12/f1') # => {"id"=>10, "oct"=>10, "hex"=>241}
```

You can even register this type for usage with `Mustermann.new`:

``` ruby
Mustermann.register(:my_flask, MyFlask)
pattern = Mustermann.new('/<id:id>/<num(base=8):oct>/<num(base=16):hex>', type: :my_flask)
pattern.params('/10/12/f1') # => {"id"=>10, "oct"=>10, "hex"=>241}
```