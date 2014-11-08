# String Scanner for Mustermann

This gem implements `Mustermann::StringScanner`, a tool inspired by Ruby's [`StringScanner`]() class.

``` ruby
require 'mustermann/string_scanner'
scanner = Mustermann::StringScanner.new("here is our example string")

scanner.scan("here") # => "here"
scanner.getch        # => " "

if scanner.scan(":verb our")
  scanner.scan(:noun, capture: :word)
  scanner[:verb]  # => "is"
  scanner[:nound] # => "example"
end

scanner.rest # => "string"
```

You can pass it pattern objects directly:

``` ruby
pattern = Mustermann.new(':name')
scanner.check(pattern)
```

Or have `#scan` (and other methods) check these for you.

``` ruby
scanner.check('{name}', type: :template)
```

You can also pass in default options for ad hoc patterns when creating the scanner:

``` ruby
scanner = Mustermann::StringScanner.new(input, type: :shell)
```