# The Amazing Mustermann

[![Build Status](https://github.com/sinatra/mustermann/actions/workflows/test.yml/badge.svg)](https://github.com/sinatra/mustermann/actions/workflows/test.yml) [![Coverage Status](https://coveralls.io/repos/github/sinatra/mustermann/badge.svg?branch=main)](https://coveralls.io/github/sinatra/mustermann?branch=main) [![Gem Version](https://img.shields.io/gem/v/mustermann.svg)](https://rubygems.org/gems/mustermann)
[![Inline docs](http://inch-ci.org/github/rkh/mustermann.svg)](http://inch-ci.org/github/rkh/mustermann)
[![Documentation](http://img.shields.io/:yard-docs-38c800.svg)](https://gemdocs.org/gems/mustermann/)
[![License](http://img.shields.io/:license-MIT-38c800.svg)](http://rkh.mit-license.org)
[![Badges](http://img.shields.io/:badges-7/7-38c800.svg)](http://img.shields.io)

This repository contains two projects (each installable as separate gems):

* **[mustermann](https://github.com/sinatra/mustermann/blob/main/mustermann/README.md): Your personal string matching expert. This is probably what you're looking for.**
* [mustermann-contrib](https://github.com/sinatra/mustermann/blob/main/mustermann-contrib/README.md): A gem with additional pattern types and extensions.

## Projects using Mustermann

Mustermann is typically used by other frameworks and libraries, primarily but not exclusively for handing HTTP requests.

These include, amongst others:

* [Sinatra](https://sinatrarb.com/):
  A DSL for quickly creating web applications with minimal effort
* [Hanami](https://hanamirb.org/):
  A flexible framework for maintainable Ruby apps
* [Grape](https://www.ruby-grape.org/):
  An opinionated framework for creating REST-like APIs in Ruby.
* [Padrino](http://padrinorb.com/):
  A Ruby web framework built upon Sinatra.
* [Praxis](https://github.com/praxis/praxis):
  A framework that focuses on both the design and implementation aspects of creating APIs.
* [Webspicy](https://yourbackendisbroken.dev/):
  A technology agnostic specification and test framework that yields better coverage for less testing effort.
* [Alchemrest](https://github.com/Betterment/alchemrest):
  Betterment's library for building robust, reliable, performant integrations with third party APIs, with a focus on making APIs work with the rest of your domain layer not against it.
* [HTTP Fake](https://alchemists.io/projects/http-fake):
  An HTTP fake implementation for test suites.
* [oas_parser](https://github.com/Nexmo/oas_parser) and [oas_parser_reborn](https://github.com/MarioRuiz/oas_parser_reborn):
  An open source Open API Spec 3 Definition Parser
* [Pendragon](https://github.com/namusyaka/pendragon):
  Provides an HTTP router and its toolkit for use in Rack. As a Rack application, it makes it easy to define complicated routing.
* [Wayferer](https://rubygems.org/gems/wayfarer):
  Web crawling framework based on ActiveJob.
* [apiculture](https://rubygems.org/gems/apiculture):
  A toolkit for building REST APIs on top of Rack. By WeTransfer.

## Git versions with Bundler

You can easily use the latest edge version from GitHub of any of these gems via [Bundler](http://bundler.io/):

``` ruby
github 'sinatra/mustermann' do
  gem 'mustermann'
  gem 'mustermann-contrib'
end
```

<a name="-pattern-types"></a>
## Pattern Types

The `identity`, `regexp`, `rails`, and `sinatra` types are included in the `mustermann` gem, all the other types listed here are part of the `mustermann-contrib` gem. There are also third-party gems providing additional types, like [mustermann-grape](https://github.com/ruby-grape/mustermann-grape).

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

Ruby 3.3+ compatible Ruby implementation (MRI, JRuby, and TruffleRuby are tested).
