# frozen_string_literal: true
require 'support'
require 'mustermann/express'

describe Mustermann::Express do
  extend Support::Pattern

  pattern '' do
    it { should     match('')  }
    it { should_not match('/') }

    it { should expand.to('') }
    it { should_not expand(a: 1) }

    it { should generate_template('') }

    it { should respond_to(:expand)       }
    it { should respond_to(:to_templates) }
  end

  pattern '/' do
    it { should     match('/')    }
    it { should_not match('/foo') }

    it { should expand.to('/') }
    it { should_not expand(a: 1) }
  end

  pattern '/foo' do
    it { should     match('/foo')     }
    it { should_not match('/bar')     }
    it { should_not match('/foo.bar') }

    it { should expand.to('/foo') }
    it { should_not expand(a: 1) }
  end

  pattern '/foo/bar' do
    it { should     match('/foo/bar')   }
    it { should_not match('/foo%2Fbar') }
    it { should_not match('/foo%2fbar') }

    it { should expand.to('/foo/bar') }
    it { should_not expand(a: 1) }
  end

  pattern '/:foo' do
    it { should match('/foo')       .capturing foo: 'foo'       }
    it { should match('/bar')       .capturing foo: 'bar'       }
    it { should match('/foo.bar')   .capturing foo: 'foo.bar'   }
    it { should match('/%0Afoo')    .capturing foo: '%0Afoo'    }
    it { should match('/foo%2Fbar') .capturing foo: 'foo%2Fbar' }

    it { should_not match('/foo?')    }
    it { should_not match('/foo/bar') }
    it { should_not match('/')        }
    it { should_not match('/foo/')    }

    example { pattern.params('/foo')   .should be == {"foo" => "foo"} }
    example { pattern.params('/f%20o') .should be == {"foo" => "f o"} }
    example { pattern.params('').should be_nil }

    it { should expand(foo: 'bar')     .to('/bar')       }
    it { should expand(foo: 'b r')     .to('/b%20r')     }
    it { should expand(foo: 'foo/bar') .to('/foo%2Fbar') }

    it { should_not expand(foo: 'foo', bar: 'bar') }
    it { should_not expand(bar: 'bar') }
    it { should_not expand }

    it { should generate_template('/{foo}') }
  end

  pattern '/:foo+' do
    it { should_not match('/') }
    it { should match('/foo')     .capturing foo: 'foo' }
    it { should match('/foo/bar') .capturing foo: 'foo/bar' }

    it { should expand                  .to('/')        }
    it { should expand(foo:  nil)       .to('/')        }
    it { should expand(foo:  '')        .to('/')        }
    it { should expand(foo: 'foo')      .to('/foo')     }
    it { should expand(foo: 'foo/bar')  .to('/foo/bar') }
    it { should expand(foo: 'foo.bar')  .to('/foo.bar') }

    it { should generate_template('/{+foo}') }
  end

  pattern '/:foo?' do
    it { should match('/foo')       .capturing foo: 'foo'       }
    it { should match('/bar')       .capturing foo: 'bar'       }
    it { should match('/foo.bar')   .capturing foo: 'foo.bar'   }
    it { should match('/%0Afoo')    .capturing foo: '%0Afoo'    }
    it { should match('/foo%2Fbar') .capturing foo: 'foo%2Fbar' }
    it { should match('/') }

    it { should_not match('/foo?')    }
    it { should_not match('/foo/bar') }
    it { should_not match('/foo/')    }

    example { pattern.params('/foo')   .should be == {"foo" => "foo"} }
    example { pattern.params('/f%20o') .should be == {"foo" => "f o"} }
    example { pattern.params('/')      .should be == {"foo" => nil  } }

    it { should expand(foo: 'bar')     .to('/bar')       }
    it { should expand(foo: 'b r')     .to('/b%20r')     }
    it { should expand(foo: 'foo/bar') .to('/foo%2Fbar') }
    it { should expand                 .to('/')          }

    it { should_not expand(foo: 'foo', bar: 'bar') }
    it { should_not expand(bar: 'bar') }

    it { should generate_template('/{foo}') }
    it { should generate_template('/')      }
  end

  pattern '/:foo*' do
    it { should match('/')        .capturing foo: '' }
    it { should match('/foo')     .capturing foo: 'foo' }
    it { should match('/foo/bar') .capturing foo: 'foo/bar' }

    it { should expand                  .to('/')        }
    it { should expand(foo:  nil)       .to('/')        }
    it { should expand(foo:  '')        .to('/')        }
    it { should expand(foo: 'foo')      .to('/foo')     }
    it { should expand(foo: 'foo/bar')  .to('/foo/bar') }
    it { should expand(foo: 'foo.bar')  .to('/foo.bar') }

    it { should generate_template('/{+foo}') }
  end

  pattern '/:foo(.*)' do
    it { should match('/')        .capturing foo: '' }
    it { should match('/foo')     .capturing foo: 'foo' }
    it { should match('/foo/bar') .capturing foo: 'foo/bar' }

    it { should expand(foo:  '')        .to('/')        }
    it { should expand(foo: 'foo')      .to('/foo')     }
    it { should expand(foo: 'foo/bar')  .to('/foo/bar') }
    it { should expand(foo: 'foo.bar')  .to('/foo.bar') }

    it { should generate_template('/{foo}') }
  end

  pattern '/:foo(\d+)' do
    it { should_not match('/')    }
    it { should_not match('/foo') }
    it { should match('/15') .capturing foo: '15' }
    it { should generate_template('/{foo}') }
  end

  pattern '/:foo(\d+|bar)' do
    it { should_not match('/')    }
    it { should_not match('/foo') }
    it { should match('/15')  .capturing foo: '15' }
    it { should match('/bar') .capturing foo: 'bar' }
    it { should generate_template('/{foo}') }
  end

  pattern '/:foo(\))' do
    it { should_not match('/')    }
    it { should_not match('/foo') }
    it { should match('/)').capturing foo: ')' }
    it { should generate_template('/{foo}') }
  end

  pattern '/:foo(prefix(\d+|bar))' do
    it { should_not match('/prefix')    }
    it { should_not match('/prefixfoo') }
    it { should match('/prefix15')  .capturing foo: 'prefix15' }
    it { should match('/prefixbar') .capturing foo: 'prefixbar' }
    it { should generate_template('/{foo}') }
  end

  pattern '/(.+)' do
    it { should_not match('/') }
    it { should match('/foo')     .capturing splat: 'foo' }
    it { should match('/foo/bar') .capturing splat: 'foo/bar' }
    it { should generate_template('/{+splat}') }
  end

  pattern '/(foo(a|b))' do
    it { should_not match('/') }
    it { should match('/fooa') .capturing splat: 'fooa' }
    it { should match('/foob') .capturing splat: 'foob' }
    it { should generate_template('/{+splat}') }
  end

  context 'invalid syntax' do
    example 'unexpected closing parenthesis' do
      expect { Mustermann::Express.new('foo)bar') }.
        to raise_error(Mustermann::ParseError, 'unexpected ) while parsing "foo)bar"')
    end

    example 'missing closing parenthesis' do
      expect { Mustermann::Express.new('foo(bar') }.
        to raise_error(Mustermann::ParseError, 'unexpected end of string while parsing "foo(bar"')
    end

    example 'unexpected ?' do
      expect { Mustermann::Express.new('foo?bar') }.
        to raise_error(Mustermann::ParseError, 'unexpected ? while parsing "foo?bar"')
    end

    example 'unexpected *' do
      expect { Mustermann::Express.new('foo*bar') }.
        to raise_error(Mustermann::ParseError, 'unexpected * while parsing "foo*bar"')
    end
  end
end
