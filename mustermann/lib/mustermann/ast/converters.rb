# frozen_string_literal: true
require "rubygems/version"
require "date"

module Mustermann
  module AST
    CONVERTERS = {
      "Integer" => [ /-?\d+/,           :to_i   ],
      "Symbol"  => [ /\w+/,             :to_sym ],
      "String"  => [ nil,               :to_s   ],
      "Float"   => [ /-?\d+(?:\.\d+)?/, :to_f   ],

      "Date"    => [
        /\d{4}-\d{2}-\d{2}/,
        ->(string) { Date.parse(string) }
      ],

      "Gem::Version" => [
        Regexp.new(Gem::Version::VERSION_PATTERN),
        ->(string) { Gem::Version.new(string) }
      ],

      locale: [ /(?:[A-Za-z]{2,3}|i)(-[A-Za-z0-9]{1,8})*/ ],
      slug:   [ /[a-z0-9]+(?:-[a-z0-9]+)*/ ],
      uuid:   [ /[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/i ],
    }

    CONVERTERS.merge!({
      integer: CONVERTERS["Integer"],
      symbol:  CONVERTERS["Symbol"],
      string:  CONVERTERS["String"],
      float:   CONVERTERS["Float"],
      date:    CONVERTERS["Date"],
      version: CONVERTERS["Gem::Version"],
    })

    CONVERTERS.freeze

    private_constant :CONVERTERS
  end
end
