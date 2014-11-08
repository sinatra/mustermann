# The Amazing Mustermann

This repository contains multiple projects (each installable as separate gems).

* **[mustermann](mustermann/README.md): Your personal string matching expert. This is probably what you're looking for.**
* [mustermann-strscan](mustermann-strscan/README.md): A version of Ruby's [StringScanner](http://ruby-doc.org/stdlib-2.0/libdoc/strscan/rdoc/StringScanner.html) made for pattern objects.
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
      <th><a href="mustermann-cake/README.md"><tt>cake</tt></a></th>
      <td><tt>/:prefix/**</tt></td>
      <td><a href="http://cakephp.org/">CakePHP</a></td>
      <td></td>
    </tr>

    <tr>
      <th><a href="mustermann-express/README.md"><tt>express</tt></a></th>
      <td><tt>/:prefix+/:id(\d+)</tt></td>
      <td>
        <a href="http://expressjs.com/">Express</a>,
        <a href="https://pillarjs.github.io/">pillar.js</a>
      </td>
      <td></td>
    </tr>

    <tr>
      <th><a href="mustermann-flask/README.md"><tt>flask</tt></a></th>
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
        Exact string matching (no parameter parsing).<br>
        Does not support expanding.
      </td>
    </tr>

    <tr>
      <th><a href="mustermann-pyramid/README.md"><tt>pyramid</tt></a></th>
      <td><tt>/{prefix:.*}/{id}</tt></td>
      <td>
        <a href="http://www.pylonsproject.org/projects/pyramid/about">Pyramid</a>,
        <a href="http://www.pylonsproject.org/projects/pylons-framework/about">Pylons</a>
      </td>
      <td></td>
    </tr>

    <tr>
      <th><a href="mustermann-rails/README.md"><tt>rails</tt></a></th>
      <td><tt>/:slug(.:ext)</tt></td>
      <td>
        <a href="http://rubyonrails.org/">Ruby on Rails</a>,
        <a href="https://github.com/rails/journey">Journey</a>,
        <a href="https://github.com/joshbuddy/http_router">HTTP Router</a>,
        <a href="http://lotusrb.org/">Lotus</a>,
        <a href="http://www.scalatra.org/">Scalatra</a> (if <a href="http://www.scalatra.org/2.3/guides/http/routes.html#toc_248">configured</a>)</td>
      <td></td>
    </tr>

    <tr>
      <th><a href="mustermann-regexp/README.md"><tt>regexp</tt></a></th>
      <td><tt>/(?&lt;slug&gt;[^\/]+)</tt></td>
      <td>
        <a href="http://www.geocities.jp/kosako3/oniguruma/">Oniguruma</a>,
        <a href="https://github.com/k-takata/Onigmo">Onigmo<a>,
        regular expressions
      </td>
      <td>
        Created when you pass a regexp to <tt>Mustermann.new</tt>.<br>
        Does not support expanding or generating templates.
      </td>
    </tr>

    <tr>
      <th><a href="mustermann-shell/README.md"><tt>shell</tt></a></th>
      <td><tt>/*.{png,jpg}</tt></td>
      <td>Unix Shell (bash, zsh)</td>
      <td>Does not support expanding or generating templates.</td>
    </tr>

    <tr>
      <th><a href="mustermann-simple/README.md"><tt>simple</tt></a></th>
      <td><tt>/:slug.:ext</tt></td>
      <td>
        <a href="http://www.sinatrarb.com/">Sinatra</a> (1.x),
        <a href="http://www.scalatra.org/">Scalatra</a>,
        <a href="http://perldancer.org/">Dancer</a>
      </td>
      <td>
        Implementation is a direct copy from Sinatra 1.3.<br>
        Does not support expanding or generating templates.
      </td>
    </tr>

    <tr>
      <th><a href="mustermann/README.md#-sinatra-pattern"><tt>sinatra</tt></a></th>
      <td><tt>/:slug(.:ext)?</tt></td>
      <td>
        <a href="http://www.sinatrarb.com/">Sinatra</a> (2.x),
        <a href="http://www.padrinorb.com/">Padrino</a> (>= 0.13.0),
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
      <th><a href="mustermann-uri-template/README.md"><tt>uri-template</tt></a></th>
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

## Release History

Mustermann follows [Semantic Versioning 2.0](http://semver.org/). Anything documented in the README or via YARD and not declared private is part of the public API.

### Stable Releases

There have been no stable releases yet. The code base is considered solid but I only know of a small number of actual production usage.
As there has been no stable release yet, the API might still change, though I consider this unlikely.

### Development Releases

* **Mustermann 0.3.1** (2014-09-12)
    * More Infos:
      [RubyGems.org](http://rubygems.org/gems/mustermann/versions/0.3.1),
      [RubyDoc.info](http://rubydoc.info/gems/mustermann/0.3.1/frames),
      [GitHub.com](https://github.com/rkh/mustermann/tree/v0.3.1)
    * Speed up pattern generation and matching (thanks [Daniel Mendler](https://github.com/minad))
    * Small change so `Mustermann === Mustermann.new('...')` returns `true`.
* **Mustermann 0.3.0** (2014-08-18)
    * More Infos:
      [RubyGems.org](http://rubygems.org/gems/mustermann/versions/0.3.0),
      [RubyDoc.info](http://rubydoc.info/gems/mustermann/0.3.0/frames),
      [GitHub.com](https://github.com/rkh/mustermann/tree/v0.3.0)
    * Add `regexp` pattern.
    * Add named splats to Sinatra patterns.
    * Add `Mustermann::Mapper`.
    * Improve duck typing support.
    * Improve documentation.
* **Mustermann 0.2.0** (2013-08-24)
    * More Infos:
      [RubyGems.org](http://rubygems.org/gems/mustermann/versions/0.2.0),
      [RubyDoc.info](http://rubydoc.info/gems/mustermann/0.2.0/frames),
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
      [RubyGems.org](http://rubygems.org/gems/mustermann/versions/0.1.0),
      [RubyDoc.info](http://rubydoc.info/gems/mustermann/0.1.0/frames),
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
      [RubyGems.org](http://rubygems.org/gems/mustermann/versions/0.0.1),
      [RubyDoc.info](http://rubydoc.info/gems/mustermann/0.0.1/frames),
      [GitHub.com](https://github.com/rkh/mustermann/tree/v0.0.1)
    * Initial Release.

### Upcoming Releases

* **Mustermann 0.4.0** (next release with new features)
    * Add `Pattern#to_proc`.
    * Add `Pattern#|`, `Pattern#&` and `Pattern#^`.
    * Add `Pattern#peek`, `Pattern#peek_size`, `Pattern#peek_match` and `Pattern#peek_params`.
    * Add `Mustermann::StringScanner`.
    * Add `Pattern#to_templates`.
    * Add `|` syntax to `sinatra` templates.
    * Add template style placeholders to `sinatra` templates.
    * Add `cake`, `express`, `flask` and `pyramid` patterns.
    * Allow passing in additional value behavior directly to `Pattern#expand`.
* **Mustermann 1.0.0** (before Sinatra 2.0)
    * First stable release.