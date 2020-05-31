# The Amazing Mustermann

[![Build Status](https://travis-ci.org/sinatra/mustermann.svg?branch=master)](https://travis-ci.org/sinatra/mustermann) [![Coverage Status](https://coveralls.io/repos/github/rkh/mustermann/badge.svg?branch=master)](https://coveralls.io/github/rkh/mustermann?branch=master) [![Code Climate](https://img.shields.io/codeclimate/github/rkh/mustermann.svg)](https://codeclimate.com/github/rkh/mustermann) [![Gem Version](https://img.shields.io/gem/v/mustermann.svg)](https://rubygems.org/gems/mustermann)
[![Inline docs](http://inch-ci.org/github/rkh/mustermann.svg)](http://inch-ci.org/github/rkh/mustermann)
[![Documentation](http://img.shields.io/:yard-docs-38c800.svg)](http://www.rubydoc.info/gems/mustermann/frames)
[![License](http://img.shields.io/:license-MIT-38c800.svg)](http://rkh.mit-license.org)
[![Badges](http://img.shields.io/:badges-9/9-38c800.svg)](http://img.shields.io)

This repository contains multiple projects (each installable as separate gems).

* **[mustermann](https://github.com/sinatra/mustermann/blob/master/mustermann/README.md): Your personal string matching expert. This is probably what you're looking for.**
* [mustermann-contrib](https://github.com/sinatra/mustermann/blob/master/mustermann-contrib/README.md): A meta gem depending on all other official mustermann gems.
* [mustermann-fileutils](https://github.com/sinatra/mustermann/blob/master/mustermann-contrib/README.md#-mustermann-fileutils): Efficient file system operations using Mustermann patterns.
* [mustermann-strscan](https://github.com/sinatra/mustermann/blob/master/mustermann-contrib/README.md#-mustermann-strscan): A version of Ruby's [StringScanner](http://ruby-doc.org/stdlib-2.0/libdoc/strscan/rdoc/StringScanner.html) made for pattern objects.
* [mustermann-visualizer](https://github.com/sinatra/mustermann/blob/master/mustermann-contrib/README.md#-mustermann-visualizer): Syntax highlighting and tree visualization for patterns.'
* A selection of pattern types for mustermann, each as their own little library, see [below](#-pattern-types).

## Git versions with Bundler

You can easily use the latest edge version from GitHub of any of these gems via [Bundler](http://bundler.io/):

``` ruby
git 'https://github.com/rkh/mustermann.git' do
  gem 'mustermann'
  gem 'mustermann-rails'
end
```

<a name="-pattern-types"></a>
## Pattern Types

The `identity`, `regexp` and `sinatra` types are included in the `mustermann` gem, all the other types have their own gems.

<table>
  <thead>
    <tr>
      <th>Type</th>
      <th>Example</th>
      <th>Compatible with</th>
      <th>Notes</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th><a href="mustermann-contrib/README.md#-mustermann-cake"><tt>cake</tt></a></th>
      <td><tt>/:prefix/**</tt></td>
      <td><a href="http://cakephp.org/">CakePHP</a></td>
      <td></td>
    </tr>
    <tr>
      <th><a href="mustermann-contrib/README.md#-mustermann-express"><tt>express</tt></a></th>
      <td><tt>/:prefix+/:id(\d+)</tt></td>
      <td>
        <a href="http://expressjs.com/">Express</a>,
        <a href="https://pillarjs.github.io/">pillar.js</a>
      </td>
      <td></td>
    </tr>
    <tr>
      <th><a href="mustermann-contrib/README.md#-mustermann-flask"><tt>flask</tt></a></th>
      <td><tt>/&lt;prefix&gt;/&lt;int:id&gt;</tt></td>
      <td>
        <a href="http://flask.pocoo.org/">Flask</a>,
        <a href="http://werkzeug.pocoo.org/">Werkzeug</a>
      </td>
      <td></td>
    </tr>
    <tr>
      <th><a href="mustermann/README.md#-identity-pattern"><tt>identity</tt></a></th>
      <td><tt>/image.png</tt></td>
      <td>any software using strings</td>
      <td>
        Exact string matching (no parameter parsing).
      </td>
    </tr>
    <tr>
      <th><a href="mustermann-contrib/README.md#-mustermann-pyramid"><tt>pyramid</tt></a></th>
      <td><tt>/{prefix:.*}/{id}</tt></td>
      <td>
        <a href="http://www.pylonsproject.org/projects/pyramid/about">Pyramid</a>,
        <a href="http://www.pylonsproject.org/projects/pylons-framework/about">Pylons</a>
      </td>
      <td></td>
    </tr>
    <tr>
      <th><a href="mustermann-contrib/README.md#-mustermann-rails"><tt>rails</tt></a></th>
      <td><tt>/:slug(.:ext)</tt></td>
      <td>
        <a href="http://rubyonrails.org/">Ruby on Rails</a>,
        <a href="https://github.com/rails/journey">Journey</a>,
        <a href="https://github.com/joshbuddy/http_router">HTTP Router</a>,
        <a href="http://hanamirb.org">Hanami</a>,
        <a href="http://scalatra.org/">Scalatra</a> (if <a href="http://scalatra.org/2.3/guides/http/routes.html#toc_248">configured</a>),
        <a href="https://github.com/alisnic/nyny">NYNY</a></td>
      <td></td>
    </tr>
    <tr>
      <th><a href="mustermann/README.md#-regexp-pattern"><tt>regexp</tt></a></th>
      <td><tt>/(?&lt;slug&gt;[^\/]+)</tt></td>
      <td>
        <a href="https://github.com/kkos/oniguruma">Oniguruma</a>,
        <a href="https://github.com/k-takata/Onigmo">Onigmo<a>,
        regular expressions
      </td>
      <td>
        Created when you pass a regexp to <tt>Mustermann.new</tt>.<br>
        Does not support expanding or generating templates.
      </td>
    </tr>
    <tr>
      <th><a href="mustermann-contrib/README.md#-mustermann-shell"><tt>shell</tt></a></th>
      <td><tt>/*.{png,jpg}</tt></td>
      <td>Unix Shell (bash, zsh)</td>
      <td>Does not support expanding or generating templates.</td>
    </tr>
    <tr>
      <th><a href="mustermann-contrib/README.md#-mustermann-simple"><tt>simple</tt></a></th>
      <td><tt>/:slug.:ext</tt></td>
      <td>
        <a href="http://www.sinatrarb.com/">Sinatra</a> (1.x),
        <a href="http://scalatra.org/">Scalatra</a>,
        <a href="http://perldancer.org/">Dancer</a>,
        <a href="http://twitter.github.io/finatra/">Finatra</a>,
        <a href="http://sparkjava.com/">Spark</a>,
        <a href="https://github.com/rc1/RCRouter">RCRouter</a>,
        <a href="https://github.com/kissjs/kick.js">kick.js</a>
      </td>
      <td>
        Implementation is a direct copy from Sinatra 1.3.<br>
        It is the predecessor of <tt>sinatra</tt>.
        Does not support expanding or generating templates.
      </td>
    </tr>
    <tr>
      <th><a href="mustermann/README.md#-sinatra-pattern"><tt>sinatra</tt></a></th>
      <td><tt>/:slug(.:ext)?</tt></td>
      <td>
        <a href="http://www.sinatrarb.com/">Sinatra</a> (2.x),
        <a href="http://padrinorb.com/">Padrino</a> (>= 0.13.0),
        <a href="https://github.com/namusyaka/pendragon">Pendragon</a>,
        <a href="https://github.com/kenichi/angelo">Angelo</a>
      </td>
      <td>
        <u>This is the default</u> and the only type "invented here".<br>
        It is a superset of <tt>simple</tt> and has a common subset with
        <tt>template</tt> (and others).
      </td>
    </tr>
    <tr>
      <th><a href="mustermann-contrib/README.md#-mustermann-uri-template"><tt>uri-template</tt></a></th>
      <td><tt>/{+pre}/{page}{?q}</tt></td>
      <td>
        <a href="https://tools.ietf.org/html/rfc6570">RFC 6570</a>,
        <a href="http://jsonapi.org/">JSON API</a>,
        <a href="http://tools.ietf.org/html/draft-nottingham-json-home-02">JSON Home Documents</a>
        and <a href="https://code.google.com/p/uri-templates/wiki/Implementations">many more</a>
      </td>
      <td>Standardized URI templates, can be <a href="mustermann/README.md#-generating-templates">generated</a> from most other types.</td>
    </tr>
  </tbody>
</table>

Any software using Mustermann is obviously compatible with at least one of the above.

## Requirements

Mustermann depends on [tool](https://github.com/rkh/tool) (which has been extracted from Mustermann and Sinatra 2.0), and a Ruby 2.2+ compatible Ruby implementation.

It is known to work on MRI 2.2 through 2.7. JRuby and Rubinius support is unknown.

If you need Ruby 1.9 support, you might be able to use the **unofficial** [mustermann19](https://rubygems.org/gems/mustermann19) gem based on [namusyaka's fork](https://github.com/namusyaka/mustermann19).

## Release History

Mustermann follows [Semantic Versioning 2.0](http://semver.org/). Anything documented in the README or via YARD and not declared private is part of the public API.

### Stable Releases

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

### Development Releases

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
