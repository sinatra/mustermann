# Changelog

Mustermann follows [Semantic Versioning 2.0](http://semver.org/). Anything documented in the README or via YARD and not declared private is part of the public API.

## Upcoming Releases

### Mustermann 4.0.0

#### Breaking changes

* `Mustermann::Pattern#match` will now return `Mustermann::Match` instead of either `MatchData` or `Mustermann::SimpleMatch`.
  This object behaves similar to the previous return values, but also implements `#params` and `#pattern`. Positional access to captures is no longer supported.
* Moved `Mustermann::Mapper` and `Mustermann::PatternCache` from `mustermann` to `mustermann-contrib`.
* Removed special code for Sinatra 1.x. If you want to use Mustermann with Sinatra, please upgrade to any of the Sinatra versions released since 2017.
  
#### New features

* `Mustermann::Rails` now supports Rails up to version 8.2 (previously 5.0).
* Added `Mustermann::Hybrid`, a pattern that's a union of Sinatra, Rails and URI Template syntax. It is designed to be as compatible as possible with all three syntaxes.
* Added `Mustermann::Set` to `mustermann`, which is a collection of patterns with associated values, designed for building routing tables that dispatch efficiently as the number of routes grows.
* Reintroduce `Mustermann::Router`, now based on `Mustermann::Set`, for demonstration purposes and use in small applications or middleware. Simple and fast.
* The `capture` option now supports special class and symbol values, that both set an expected capture pattern and define a params converter.

Here's an example using `Mustermann::Hybrid`, `Mustermann::Set`, and the new `capture` options:

```ruby
require "mustermann/set"

set = Mustermann::Set.new(type: :hybrid, capture: { id: Integer, user_id: Integer, slug: :slug })

# adding values is optional
set.add "/users",                "users.index"
set.add "/users/:id",            "users.show"
set.add "/posts",                "posts.index"
set.add "/users/:user_id/posts", "posts.index"
set.add "/posts/:id(-:slug)",    "posts.show" # slug is optional

match = set.match("/posts/42-awesome-post")

# id is automatically converted to an Integer, and slug is available as a string
match.params # => { id: 42, slug: "awesome-post" }

# You can access the pattern and value that matched
match.value   # => "posts.show"
match.pattern # => #<Mustermann::Hybrid:"/posts/:id(-:slug)">

# Generate a path from a set value and params
set.expand("posts.index")              # => "/posts"
set.expand("posts.index", user_id: 42) # => "/users/42/posts"
```
  
#### Performance improvements

* Small to moderate improvements for compiling complex patterns. Major improvements for simple patterns, which are common in web applications.
* Automatically switch between different matching algorithms for `Mustermann::Set` based on number of patterns. This makes it blazing fast both for small and large sets of patterns.
* Major performance improvements for `Mustermann::Mapper`, as it is based on `Mustermann::Set` now, and can dispatch in logarithmic time instead of linear time.
* Major speed improvements for sub-segment patterns with optional elements (like a format at the end of a path). These patterns are common in web applications.

 | Scenario                      | Improvement over 3.1  |
 | ----------------------------- | --------------------- |
 | Simple pattern compilation    | 6x speedup            |
 | Complex pattern compilation   | 30% speedup           |
 | Simple param extraction       | 2.4x speedup          |
 | Complex param extraction      | 70% speedup           |
 | Matching a simple pattern     | Same performance      |
 | Matching a complex pattern    | 8x speedup            |
 | Matching against 1k patterns  | 20x to 350x speedup   |
 | Matching against 10k patterns | 200x to 3500x speedup |

 Numbers are based on simple and realistic patterns run on MRI Ruby 4.0 on a MacBook Pro. The improvements you will see may vary based on your Ruby implementation, platform and patterns used.

 Simple and complex in the above table refer to patterns with only static segments or captures matching exactly one segment each (like `/resource/:id` or `/:controller/:action`) versus patterns with more complex captures (like `/resource/*path/:id` or `/resource/:id(.:format)?`). The matching improvements against 1k and 10k patterns assume the new `Mustermann::Set` is used. Otherwise the difference should be in line with the single pattern matching improvements.

#### Housekeeping

* Drop support for Ruby before 3.3.0 (all EOL now).
* Improve documentation. Add more examples and explanations. Split individual pattern types into separate pages.
* Document how to implement custom pattern types.
* Add code of conduct and contributing guidelines. Add AI policy.

## Stable Releases

* **Mustermann 3.1.1** (2026-04-16)
    * Improve `Mustermann::Pattern#hash` to reduce the chance of collisions on JRuby and TruffleRuby. Fixes [#152](https://github.com/sinatra/mustermann/issues/152)
    * No longer inject color-codes into `Mustermann::Pattern#inspect` and `Mustermann::Pattern#pretty_print` in IRB, which was broken for newer versions of IRB. Fixes [#153](https://github.com/sinatra/mustermann/issues/153)

* **Mustermann 3.1.0** (2026-04-13)
    * Minimum Ruby version is now 2.7.0, and we dropped support for old Ruby 2.6.
    * Removed the dependency on the `ruby2_keywords` gem.
    * Moved the Rails pattern from `mustermann-contrib` to the core `mustermann` gem.
    * Reduce gem size. [#151](https://github.com/sinatra/mustermann/pull/151) [@yuri-zubov](https://github.com/yuri-zubov)

* **Mustermann 3.0.4** (2025-08-03)
    * Ruby 3.4+ compatibility: Use `URI::RFC2396_Parser` in mustermann-contrib [#146](https://github.com/sinatra/mustermann/pull/146) [@dentarg](https://github.com/dentarg)

* **Mustermann 3.0.3** (2024-09-03)
    * Fix performance issue for `Mustermann::AST::Translator#escape` [#142](https://github.com/sinatra/mustermann/pull/142) [@hsbt](https://github.com/hsbt), [@ericproulx](https://github.com/ericproulx)

* **Mustermann 3.0.2** (2024-08-09)
    * Ruby 3.4+ compatibility: "Use rfc2396 parser instead of URI::DEFAULT_PARSER" [#139](https://github.com/sinatra/mustermann/pull/139) [@hsbt](https://github.com/hsbt)

* **Mustermann 3.0.1** (2024-07-31)
    * Ruby 3.4+ compatibility: "Use URI::RFC2396_Parser#regex explicitly" [#138](https://github.com/sinatra/mustermann/pull/138) [@hsbt](https://github.com/hsbt)

* **Mustermann 3.0.0** (2022-07-24)
    * Drop support for old Rubies < 2.6.

* **Mustermann 2.0.2** (2022-07-22)
    * Further improve Ruby 3 compatibility. [#134](https://github.com/sinatra/mustermann/pull/134). [@magni-](https://github.com/magni-) 

* **Mustermann 2.0.1** (2022-07-19)
    * Properly fix Ruby 3 compatability issue, reverts [#126](https://github.com/sinatra/mustermann/pull/126).  Resolved by [#130](https://github.com/sinatra/mustermann/pull/130) [@eregon](https://github.com/eregon), [@tconst](https://github.com/tconst), [@dentarg](https://github.com/dentarg)

* **Mustermann 2.0.0** (2022-07-18)
    * Improve Ruby 3 compatibility. Removed built-in Sinatra 1 support, and moved to new mustermann-sinatra-extension gem. Fixes [#114](https://github.com/sinatra/mustermann/issues/114) [@epergo](https://github.com/epergo)

* **Mustermann 1.1.2** (2022-07-16)
    * Add compatibility with --enable=frozen-string-literal param. Fixes [#110](https://github.com/sinatra/mustermann/issues/110) [@michal-granec](https://github.com/michal-granec)

* **Mustermann 1.1.1** (2020-01-04)
    * Make sure that `require`ing ruby2_keywords when needed. Fixes [#102](https://github.com/sinatra/mustermann/issues/103) [@Annih](https://github.com/Annih)

* **Mustermann 1.1.0** (2019-12-30)
    * Proper handling of `Mustermann::ExpandError`. Fixes [#88](https://github.com/sinatra/mustermann/issues/88) [@namusyaka](https://github.com/namusyaka)
    * Support Ruby 3 keyword arguments. [@mame](https://github.com/mame)
      * At the same time, we dropped a support that accepts options followed by mappings on `Mustermann::Mapper`. [Reference commit](https://github.com/sinatra/mustermann/pull/97/commits/4e134f5b46d8e5886b0f1590f5ff3f6ea4d2e81a)
    * Improve documentation and development. [@horaciob](https://github.com/horaciob), [@epistrephein](https://github.com/epistrephein), [@jbampton](https://github.com/jbampton), [@jkowens](https://github.com/jkowens), [@junaruga](https://github.com/junaruga)

* **Mustermann 1.0.3** (2018-08-17)
    * Handle `with_look_ahead` on SafeRenderer. Fixes [sinatra/sinatra#1409](https://github.com/sinatra/sinatra/issues/1409) [@namusyaka](https://github.com/namusyaka)
    * Fix `EqualityMap#fetch` to be compatible with the fallback `Hash#fetch`. Fixes [#89](https://github.com/sinatra/mustermann/issues/89) [@eregon](https://github.com/eregon)
    * Improve code base and documentation. [@sonots](https://github.com/sonots), [@iguchi1124](https://github.com/iguchi1124)

* **Mustermann 1.0.2** (2018-02-17)
    * Look ahead same patterns as its own when concatenation. Fixes [sinatra/sinatra#1361](https://github.com/sinatra/sinatra/issues/1361) [@namusyaka](https://github.com/namusyaka)
    * Improve development support and documentation. [@EdwardBetts](https://github.com/EdwardBetts), [@284km](https://github.com/284km), [@yb66](https://github.com/yb66) and [@garybernhardt](https://github.com/garybernhardt)

* **Mustermann 1.0.1** (2017-08-26)
    #### Docs
    * Updating readme to list Ruby 2.2 as minimum [commit](https://github.com/sinatra/mustermann/commit/7c65d9637ed81c194e3d05f0ccf3cfe76f0cf53e) (@cassidycodes)
    * Fix rendering of HTML table [commit](https://github.com/sinatra/mustermann/commit/119a61f0e589cb9e917d8c901800a202bb66ff3b) (@stevenwilkin)
    * Update summary and description in gemspec file. [commit](https://github.com/sinatra/mustermann/commit/04de221a809527c2be8c3f08c40a4fcd53f2bd53) (@junaruga)
    #### Fixes
    * avoid infinite loop by removing comments when receiving extended regexp [commit](https://github.com/sinatra/mustermann/commit/fa20301167e1b22882415f1181c5e4e2d76b6ac6) (@namusyaka)
    * avoid unintended conflict of namespace [commit](https://github.com/sinatra/mustermann/commit/d3c9531d372522d693fa5f768f13dbaa1d881d88) (@namusyaka)
    * use Regexp#source instead of Regexp#inspect [commit](https://github.com/sinatra/mustermann/pull/73/commits/e9213748bda1773b1ad9838ef57a296f92c471e7) (@namusyaka)

* **Mustermann 1.0.0** (2017-03-05)
    * First stable release.
    * Includes `mustermann`, and `mustermann-contrib` gems
    * Sinatra patterns: Allow | outside of parens.
    * Add concatenation support (`Mustermann::Pattern#+`).
    * `Mustermann::Sinatra#|` may now generate a Sinatra pattern instead of a real composite.
    * Add syntax highlighting support for composite patterns.
    * Remove routers (they were out of scope for the main gem).
    * Rails patterns: Add Rails 5.0 compatibility mode, make it default.
    * Moved `tool` gem `EqualityMap` to `Mustermann::EqualityMap` in core
    * Improve documentation.

## Development Releases

* **Mustermann 0.4.0** (2014-11-26)
    * More Infos:
      [RubyGems.org](https://rubygems.org/gems/mustermann/versions/0.4.0),
      [RubyDoc.info](http://www.rubydoc.info/gems/mustermann/0.4.0/frames),
      [GitHub.com](https://github.com/rkh/mustermann/tree/v0.4.0)
    * Split into multiple gems.
    * Add `Pattern#to_proc`.
    * Add `Pattern#|`, `Pattern#&` and `Pattern#^`.
    * Add `Pattern#peek`, `Pattern#peek_size`, `Pattern#peek_match` and `Pattern#peek_params`.
    * Add `Mustermann::StringScanner`.
    * Add `Pattern#to_templates`.
    * Add `|` syntax to `sinatra` templates.
    * Add template style placeholders to `sinatra` templates.
    * Add `cake`, `express`, `flask` and `pyramid` patterns.
    * Allow passing in additional value behavior directly to `Pattern#expand`.
    * Fix expanding of multiple splats.
    * Add expanding to `identity` patterns.
    * Add `mustermann-fileutils`.
    * Make expander accept hashes with string keys.
    * Allow named splats to be named splat.
    * Support multiple Rails versions.
    * Type option can be set to nil to get the default type.
    * Add `mustermann-visualizer`.
* **Mustermann 0.3.1** (2014-09-12)
    * More Infos:
      [RubyGems.org](https://rubygems.org/gems/mustermann/versions/0.3.1),
      [RubyDoc.info](http://www.rubydoc.info/gems/mustermann/0.3.1/frames),
      [GitHub.com](https://github.com/rkh/mustermann/tree/v0.3.1)
    * Speed up pattern generation and matching (thanks [Daniel Mendler](https://github.com/minad))
    * Small change so `Mustermann === Mustermann.new('...')` returns `true`.
* **Mustermann 0.3.0** (2014-08-18)
    * More Infos:
      [RubyGems.org](https://rubygems.org/gems/mustermann/versions/0.3.0),
      [RubyDoc.info](http://www.rubydoc.info/gems/mustermann/0.3.0/frames),
      [GitHub.com](https://github.com/rkh/mustermann/tree/v0.3.0)
    * Add `regexp` pattern.
    * Add named splats to Sinatra patterns.
    * Add `Mustermann::Mapper`.
    * Improve duck typing support.
    * Improve documentation.
* **Mustermann 0.2.0** (2013-08-24)
    * More Infos:
      [RubyGems.org](https://rubygems.org/gems/mustermann/versions/0.2.0),
      [RubyDoc.info](http://www.rubydoc.info/gems/mustermann/0.2.0/frames),
      [GitHub.com](https://github.com/rkh/mustermann/tree/v0.2.0)
    * Add first class expander objects.
    * Add params casting for expander.
    * Add simple router and rack router.
    * Add weak equality map to significantly improve performance.
    * Fix Ruby warnings.
    * Improve documentation.
    * Refactor pattern validation, AST transformations.
    * Increase test coverage (from 100%+ to 100%++).
    * Improve JRuby compatibility.
    * Work around bug in 2.0.0-p0.
* **Mustermann 0.1.0** (2013-05-12)
    * More Infos:
      [RubyGems.org](https://rubygems.org/gems/mustermann/versions/0.1.0),
      [RubyDoc.info](http://www.rubydoc.info/gems/mustermann/0.1.0/frames),
      [GitHub.com](https://github.com/rkh/mustermann/tree/v0.1.0)
    * Add `Pattern#expand` for generating strings from patterns.
    * Add better internal API for working with the AST.
    * Improved documentation.
    * Avoids parsing the path twice when used as Sinatra extension.
    * Better exceptions for unknown pattern types.
    * Better handling of edge cases around extend.
    * More specs to ensure API stability.
    * Largely rework internals of Sinatra, Rails and Template patterns.
* **Mustermann 0.0.1** (2013-04-27)
    * More Infos:
      [RubyGems.org](https://rubygems.org/gems/mustermann/versions/0.0.1),
      [RubyDoc.info](http://www.rubydoc.info/gems/mustermann/0.0.1/frames),
      [GitHub.com](https://github.com/rkh/mustermann/tree/v0.0.1)
    * Initial Release.
