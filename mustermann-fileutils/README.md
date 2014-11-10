# FileUtils for Mustermann

This gem implements efficient file system operations for Mustermann patterns.

## Globbing

All operations work on a list of files described by one or more pattern.

``` ruby
require 'mustermann/file_utils'

Mustermann::FileUtils[':base.:ext'] # => ['example.txt']

Mustermann::FileUtils.glob(':base.:ext') do |file, params|
  file   # => "example.txt"
  params # => {"base"=>"example", "ext"=>"txt"}
end
```

To avoid having to loop over all files and see if they match, it will generate a glob pattern resembling the Mustermann pattern as closely as possible.

``` ruby
require 'mustermann/file_utils'

Mustermann::FileUtils.glob_pattern('/:name')                  # => '/*'
Mustermann::FileUtils.glob_pattern('src/:path/:file.(js|rb)') # => 'src/**/*/*.{js,rb}'
Mustermann::FileUtils.glob_pattern('{a,b}/*', type: :shell)   # => '{a,b}/*'

pattern = Mustermann.new('/foo/:page', '/bar/:page') # => #<Mustermann::Composite:...>
Mustermann::FileUtils.glob_pattern(pattern)          # => "{/foo/*,/bar/*}"
```

## Mapping

It is also possible to search for files and have their paths mapped onto another path in one method call:

``` ruby
require 'mustermann/file_utils'

Mustermann::FileUtils.glob_map(':base.:ext' => ':base.bak.:ext') # => {'example.txt' => 'example.bak.txt'}
Mustermann::FileUtils.glob_map(':base.:ext' => :base) { |file, mapped| mapped } # => ['example']
```

This mechanism allows things like copying, renaming and linking files:

``` ruby
require 'mustermann/file_utils'

# copies example.txt to example.bak.txt
Mustermann::FileUtils.cp(':base.:ext' => ':base.bak.:ext')

# copies Foo.app/example.txt to Foo.back.app/example.txt
Mustermann::FileUtils.cp_r(':base.:ext' => ':base.bak.:ext')

# creates a symbolic link from bin/example to lib/example.rb
Mustermann::FileUtils.ln_s('lib/:name.rb' => 'bin/:name')
```