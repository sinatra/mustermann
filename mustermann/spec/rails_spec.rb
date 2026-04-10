# frozen_string_literal: true
require 'support'
require 'mustermann/rails'

describe Mustermann::Rails do
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

  pattern '/föö' do
    it { should match("/f%C3%B6%C3%B6") }
    it { should expand.to("/f%C3%B6%C3%B6") }
    it { should_not expand(a: 1) }
  end

  pattern "/:foo/:bar" do
    it { should match('/foo/bar')               .capturing foo: 'foo',              bar: 'bar'     }
    it { should match('/foo.bar/bar.foo')       .capturing foo: 'foo.bar',          bar: 'bar.foo' }
    it { should match('/user@example.com/name') .capturing foo: 'user@example.com', bar: 'name'    }
    it { should match('/10.1/te.st')            .capturing foo: '10.1',             bar: 'te.st'   }
    it { should match('/10.1.2/te.st')          .capturing foo: '10.1.2',           bar: 'te.st'   }

    it { should_not match('/foo%2Fbar') }
    it { should_not match('/foo%2fbar') }

    example { pattern.params('/bar/foo').should be == {"foo" => "bar", "bar" => "foo"} }
    example { pattern.params('').should be_nil }

    it { should expand(foo: 'foo', bar: 'bar').to('/foo/bar') }
    it { should_not expand(foo: 'foo') }
    it { should_not expand(bar: 'bar') }

    it { should generate_template('/{foo}/{bar}') }
  end

  pattern '/hello/:person' do
    it { should match('/hello/Frank').capturing person: 'Frank' }
    it { should expand(person: 'Frank')   .to '/hello/Frank'    }
    it { should expand(person: 'Frank?')  .to '/hello/Frank%3F' }

    it { should generate_template('/hello/{person}') }
  end

  pattern '/?:foo?/?:bar?' do
    it { should match('/?hello?/?world?').capturing foo: 'hello', bar: 'world' }
    it { should_not match('/hello/world/') }
    it { should expand(foo: 'hello', bar: 'world').to('/%3Fhello%3F/%3Fworld%3F') }
    it { should generate_template('/?{foo}?/?{bar}?') }
  end

  pattern '/:foo_bar' do
    it { should match('/hello').capturing foo_bar: 'hello' }
    it { should expand(foo_bar: 'hello').to('/hello') }
    it { should generate_template('/{foo_bar}') }
  end

  pattern '/*foo' do
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

  pattern '/*splat' do
    it { should match('/')        .capturing splat: '' }
    it { should match('/foo')     .capturing splat: 'foo' }
    it { should match('/foo/bar') .capturing splat: 'foo/bar' }
    it { should generate_template('/{+splat}') }
  end

  pattern '/:foo/*bar' do
    it { should match("/foo/bar/baz")     .capturing foo: 'foo',       bar: 'bar/baz'   }
    it { should match("/foo%2Fbar/baz")   .capturing foo: 'foo%2Fbar', bar: 'baz'       }
    it { should match("/foo/")            .capturing foo: 'foo',       bar: ''          }
    it { should match('/h%20w/h%20a%20y') .capturing foo: 'h%20w',     bar: 'h%20a%20y' }
    it { should_not match('/foo') }

    it { should expand(foo: 'foo')                     .to('/foo/')          }
    it { should expand(foo: 'foo',     bar: 'bar')     .to('/foo/bar')       }
    it { should expand(foo: 'foo',     bar: 'foo/bar') .to('/foo/foo/bar')   }
    it { should expand(foo: 'foo/bar', bar: 'bar')     .to('/foo%2Fbar/bar') }

    it { should generate_template('/{foo}/{+bar}') }
  end

  pattern '/test$/' do
    it { should match('/test$/') }
    it { should expand.to('/test$/') }
  end

  pattern '/te+st/' do
    it { should     match('/te+st/') }
    it { should_not match('/test/')  }
    it { should_not match('/teest/') }
    it { should expand.to('/te+st/') }
  end

  pattern "/path with spaces" do
    it { should match('/path%20with%20spaces')     }
    it { should match('/path%2Bwith%2Bspaces')     }
    it { should match('/path+with+spaces')         }
    it { should expand.to('/path%20with%20spaces') }

    it { should generate_template('/path%20with%20spaces') }
  end

  pattern '/foo&bar' do
    it { should match('/foo&bar') }
  end

  pattern '/*a/:foo/*b/*c' do
    it { should match('/bar/foo/bling/baz/boom').capturing a: 'bar', foo: 'foo', b: 'bling', c: 'baz/boom'  }
    example { pattern.params('/bar/foo/bling/baz/boom').should be == { "a" => 'bar', "foo" => 'foo', "b" => 'bling', "c" => 'baz/boom' } }
    it { should expand(a: 'bar', foo: 'foo', b: 'bling', c: 'baz/boom').to('/bar/foo/bling/baz/boom') }
    it { should generate_template('/{+a}/{foo}/{+b}/{+c}') }
  end

  pattern '/test.bar' do
    it { should     match('/test.bar') }
    it { should_not match('/test0bar') }
  end

  pattern '/:file.:ext' do
    it { should match('/pony.jpg')   .capturing file: 'pony', ext: 'jpg' }
    it { should match('/pony%2Ejpg') .capturing file: 'pony', ext: 'jpg' }
    it { should match('/pony%2ejpg') .capturing file: 'pony', ext: 'jpg' }

    it { should match('/pony%E6%AD%A3%2Ejpg') .capturing file: 'pony%E6%AD%A3', ext: 'jpg' }
    it { should match('/pony%e6%ad%a3%2ejpg') .capturing file: 'pony%e6%ad%a3', ext: 'jpg' }
    it { should match('/pony正%2Ejpg')        .capturing file: 'pony正',         ext: 'jpg' }
    it { should match('/pony正%2ejpg')        .capturing file: 'pony正',         ext: 'jpg' }
    it { should match('/pony正..jpg')         .capturing file: 'pony正.',        ext: 'jpg' }

    it { should_not match('/.jpg') }
    it { should expand(file: 'pony', ext: 'jpg').to('/pony.jpg') }
  end

  pattern '/:a(x)' do
    it { should match('/a')     .capturing a: 'a'   }
    it { should match('/xa')    .capturing a: 'xa'  }
    it { should match('/axa')   .capturing a: 'axa' }
    it { should match('/ax')    .capturing a: 'a'   }
    it { should match('/axax')  .capturing a: 'axa' }
    it { should match('/axaxx') .capturing a: 'axax' }
    it { should expand(a: 'x').to('/xx') }
    it { should expand(a: 'a').to('/ax') }

    it { should generate_template('/{a}x') }
    it { should generate_template('/{a}')  }
  end

  pattern '/:user(@:host)' do
    it { should match('/foo@bar')     .capturing user: 'foo',     host: 'bar'     }
    it { should match('/foo.foo@bar') .capturing user: 'foo.foo', host: 'bar'     }
    it { should match('/foo@bar.bar') .capturing user: 'foo',     host: 'bar.bar' }

    it { should expand(user: 'foo')              .to('/foo')     }
    it { should expand(user: 'foo', host: 'bar') .to('/foo@bar') }

    it { should generate_template('/{user}')        }
    it { should generate_template('/{user}@{host}') }
  end

  pattern '/:file(.:ext)' do
    it { should match('/pony')           .capturing file: 'pony', ext: nil   }
    it { should match('/pony.jpg')       .capturing file: 'pony', ext: 'jpg' }
    it { should match('/pony%2Ejpg')     .capturing file: 'pony', ext: 'jpg' }
    it { should match('/pony%2ejpg')     .capturing file: 'pony', ext: 'jpg' }
    it { should match('/pony.png.jpg')   .capturing file: 'pony.png', ext: 'jpg' }
    it { should match('/pony.')          .capturing file: 'pony.' }
    it { should_not match('/.jpg')  }

    it { should expand(file: 'pony')              .to('/pony')     }
    it { should expand(file: 'pony', ext: 'jpg')  .to('/pony.jpg') }

    it { should generate_template('/{file}')       }
    it { should generate_template('/{file}.{ext}') }
  end

  pattern '/:id/test.bar' do
    it { should match('/3/test.bar')   .capturing id: '3'   }
    it { should match('/2/test.bar')   .capturing id: '2'   }
    it { should match('/2E/test.bar')  .capturing id: '2E'  }
    it { should match('/2e/test.bar')  .capturing id: '2e'  }
    it { should match('/%2E/test.bar') .capturing id: '%2E' }
  end

  pattern '/10/:id' do
    it { should match('/10/test')  .capturing id: 'test'  }
    it { should match('/10/te.st') .capturing id: 'te.st' }
  end

  pattern '/10.1/:id' do
    it { should match('/10.1/test')  .capturing id: 'test'  }
    it { should match('/10.1/te.st') .capturing id: 'te.st' }
  end

  pattern '/:foo.:bar/:id' do
    it { should match('/10.1/te.st')   .capturing foo: "10",   bar: "1", id: "te.st" }
    it { should match('/10.1.2/te.st') .capturing foo: "10.1", bar: "2", id: "te.st" }
  end

  pattern '/:a/:b(.)(:c)' do
    it { should match('/a/b')     .capturing a: 'a',   b: 'b', c: nil }
    it { should match('/a/b.c')   .capturing a: 'a',   b: 'b', c: 'c' }
    it { should match('/a.b/c')   .capturing a: 'a.b', b: 'c', c: nil }
    it { should match('/a.b/c.d') .capturing a: 'a.b', b: 'c', c: 'd' }
    it { should_not match('/a.b/c.d/e') }

    it { should expand(a: ?a, b: ?b)        .to('/a/b.')  }
    it { should expand(a: ?a, b: ?b, c: ?c) .to('/a/b.c') }

    it { should generate_template('/{a}/{b}')      }
    it { should generate_template('/{a}/{b}.')     }
    it { should generate_template('/{a}/{b}.{c}')  }
  end

  pattern '/:a(foo:b)' do
    it { should match('/barfoobar')       .capturing a: 'bar',       b: 'bar' }
    it { should match('/barfoobarfoobar') .capturing a: 'barfoobar', b: 'bar' }
    it { should match('/bar')             .capturing a: 'bar',       b: nil   }
    it { should_not match('/') }

    it { should expand(a: ?a)        .to('/a')     }
    it { should expand(a: ?a, b: ?b) .to('/afoob') }

    it { should     generate_template('/{a}foo{b}') }
    it { should     generate_template('/{a}')       }
    it { should_not generate_template('/{a}foo')    }
  end

  pattern '/fo(o)' do
    it { should     match('/fo')   }
    it { should     match('/foo')  }
    it { should_not match('')      }
    it { should_not match('/')     }
    it { should_not match('/f')    }
    it { should_not match('/fooo') }

    it { should expand.to('/foo') }
  end

  pattern '/foo?' do
    it { should     match('/foo?')  }
    it { should_not match('/foo\?') }
    it { should_not match('/fo')    }
    it { should_not match('/foo')   }
    it { should_not match('')       }
    it { should_not match('/')      }
    it { should_not match('/f')     }
    it { should_not match('/fooo')  }

    it { should expand.to('/foo%3F') }
  end

  pattern '/:fOO' do
    it { should match('/a').capturing fOO: 'a' }
  end

  pattern '/:_X' do
    it { should match('/a').capturing _X: 'a' }
  end

  pattern '/:f00' do
    it { should match('/a').capturing f00: 'a' }
  end

  pattern '/:foo(/:bar)/:baz' do
    it { should match('/foo/bar/baz').capturing foo: 'foo', bar: 'bar', baz: 'baz' }
    it { should expand(foo: ?a, baz: ?b)          .to('/a/b')   }
    it { should expand(foo: ?a, baz: ?b, bar: ?x) .to('/a/x/b') }
  end

  pattern '/:foo', capture: /\d+/ do
    it { should match('/1')   .capturing foo: '1'   }
    it { should match('/123') .capturing foo: '123' }

    it { should_not match('/')    }
    it { should_not match('/foo') }
  end

  pattern '/:foo', capture: /\d+/ do
    it { should match('/1')   .capturing foo: '1'   }
    it { should match('/123') .capturing foo: '123' }

    it { should_not match('/')    }
    it { should_not match('/foo') }
  end

  pattern '/:foo', capture: '1' do
    it { should match('/1').capturing foo: '1' }

    it { should_not match('/')    }
    it { should_not match('/foo') }
    it { should_not match('/123') }
  end

  pattern '/:foo', capture: 'a.b' do
    it { should match('/a.b')   .capturing foo: 'a.b'   }
    it { should match('/a%2Eb') .capturing foo: 'a%2Eb' }
    it { should match('/a%2eb') .capturing foo: 'a%2eb' }

    it { should_not match('/ab')   }
    it { should_not match('/afb')  }
    it { should_not match('/a1b')  }
    it { should_not match('/a.bc') }
  end

  pattern '/:foo(/:bar)', capture: :alpha do
    it { should match('/abc') .capturing foo: 'abc', bar: nil }
    it { should match('/a/b') .capturing foo: 'a',   bar: 'b' }
    it { should match('/a')   .capturing foo: 'a',   bar: nil }

    it { should_not match('/1/2') }
    it { should_not match('/a/2') }
    it { should_not match('/1/b') }
    it { should_not match('/1')   }
    it { should_not match('/1/')  }
    it { should_not match('/a/')  }
    it { should_not match('//a')  }
  end

  pattern '/:foo', capture: ['foo', 'bar', /\d+/] do
    it { should match('/1')   .capturing foo: '1'   }
    it { should match('/123') .capturing foo: '123' }
    it { should match('/foo') .capturing foo: 'foo' }
    it { should match('/bar') .capturing foo: 'bar' }

    it { should_not match('/')     }
    it { should_not match('/baz')  }
    it { should_not match('/foo1') }
  end

  pattern '/:foo:bar:baz', capture: { foo: :alpha, bar: /\d+/ } do
    it { should match('/ab123xy-1') .capturing foo: 'ab', bar: '123', baz: 'xy-1' }
    it { should match('/ab123')     .capturing foo: 'ab', bar: '12',  baz: '3'    }
    it { should_not match('/123abcxy-1') }
    it { should_not match('/abcxy-1')    }
    it { should_not match('/abc1')       }
  end

  pattern '/:foo', capture: { foo: ['foo', 'bar', /\d+/] } do
    it { should match('/1')   .capturing foo: '1'   }
    it { should match('/123') .capturing foo: '123' }
    it { should match('/foo') .capturing foo: 'foo' }
    it { should match('/bar') .capturing foo: 'bar' }

    it { should_not match('/')     }
    it { should_not match('/baz')  }
    it { should_not match('/foo1') }
  end

  pattern '/:file(.:ext)', capture: { ext: ['jpg', 'png'] } do
    it { should match('/pony')         .capturing file: 'pony',     ext: nil   }
    it { should match('/pony.jpg')     .capturing file: 'pony',     ext: 'jpg' }
    it { should match('/pony%2Ejpg')   .capturing file: 'pony',     ext: 'jpg' }
    it { should match('/pony%2ejpg')   .capturing file: 'pony',     ext: 'jpg' }
    it { should match('/pony.png')     .capturing file: 'pony',     ext: 'png' }
    it { should match('/pony%2Epng')   .capturing file: 'pony',     ext: 'png' }
    it { should match('/pony%2epng')   .capturing file: 'pony',     ext: 'png' }
    it { should match('/pony.png.jpg') .capturing file: 'pony.png', ext: 'jpg' }
    it { should match('/pony.jpg.png') .capturing file: 'pony.jpg', ext: 'png' }
    it { should match('/pony.gif')     .capturing file: 'pony.gif', ext: nil   }
    it { should match('/pony.')        .capturing file: 'pony.',    ext: nil   }
    it { should_not match('.jpg') }
  end

  pattern '/:file(:ext)', capture: { ext: ['.jpg', '.png', '.tar.gz'] } do
    it { should match('/pony')         .capturing file: 'pony',     ext: nil       }
    it { should match('/pony.jpg')     .capturing file: 'pony',     ext: '.jpg'    }
    it { should match('/pony.png')     .capturing file: 'pony',     ext: '.png'    }
    it { should match('/pony.png.jpg') .capturing file: 'pony.png', ext: '.jpg'    }
    it { should match('/pony.jpg.png') .capturing file: 'pony.jpg', ext: '.png'    }
    it { should match('/pony.tar.gz')  .capturing file: 'pony',     ext: '.tar.gz' }
    it { should match('/pony.gif')     .capturing file: 'pony.gif', ext: nil       }
    it { should match('/pony.')        .capturing file: 'pony.',    ext: nil       }
    it { should_not match('/.jpg')  }
  end

  pattern '/:a(@:b)', capture: { b: /\d+/ } do
    it { should match('/a')     .capturing a: 'a',   b: nil }
    it { should match('/a@1')   .capturing a: 'a',   b: '1' }
    it { should match('/a@b')   .capturing a: 'a@b', b: nil }
    it { should match('/a@1@2') .capturing a: 'a@1', b: '2' }
  end

  pattern '/:a(b)', greedy: false do
    it { should match('/ab').capturing a: 'a' }
  end

  pattern '/:file(.:ext)', greedy: false do
    it { should match('/pony')           .capturing file: 'pony', ext: nil       }
    it { should match('/pony.jpg')       .capturing file: 'pony', ext: 'jpg'     }
    it { should match('/pony.png.jpg')   .capturing file: 'pony', ext: 'png.jpg' }
  end

  pattern '/:controller(/:action(/:id(.:format)))' do
    it { should match('/content').capturing controller: 'content' }
  end

  pattern '/fo(o)', uri_decode: false do
    it { should     match('/foo')   }
    it { should     match('/fo')    }
    it { should_not match('/fo(o)') }
  end

  pattern '/foo/bar', uri_decode: false do
    it { should     match('/foo/bar')   }
    it { should_not match('/foo%2Fbar') }
    it { should_not match('/foo%2fbar') }
  end

  pattern "/path with spaces", uri_decode: false do
    it { should     match('/path with spaces')     }
    it { should_not match('/path%20with%20spaces') }
    it { should_not match('/path%2Bwith%2Bspaces') }
    it { should_not match('/path+with+spaces')     }
  end

  pattern "/path with spaces", space_matches_plus: false do
    it { should     match('/path%20with%20spaces') }
    it { should_not match('/path%2Bwith%2Bspaces') }
    it { should_not match('/path+with+spaces')     }
  end

  context 'invalid syntax' do
    example 'unexpected closing parenthesis' do
      expect { Mustermann::Rails.new('foo)bar') }.
        to raise_error(Mustermann::ParseError, 'unexpected ) while parsing "foo)bar"')
    end

    example 'missing closing parenthesis' do
      expect { Mustermann::Rails.new('foo(bar') }.
        to raise_error(Mustermann::ParseError, 'unexpected end of string while parsing "foo(bar"')
    end
  end

  context 'invalid capture names' do
    example 'empty name' do
      expect { Mustermann::Rails.new('/:/') }.
        to raise_error(Mustermann::CompileError, "capture name can't be empty: \"/:/\"")
    end

    example 'named splat' do
      expect { Mustermann::Rails.new('/:splat/') }.
        to raise_error(Mustermann::CompileError, "capture name can't be splat: \"/:splat/\"")
    end

    example 'named captures' do
      expect { Mustermann::Rails.new('/:captures/') }.
        to raise_error(Mustermann::CompileError, "capture name can't be captures: \"/:captures/\"")
    end

    example 'with capital letter' do
      expect { Mustermann::Rails.new('/:Foo/') }.
        to raise_error(Mustermann::CompileError, "capture name must start with underscore or lower case letter: \"/:Foo/\"")
    end

    example 'with integer' do
      expect { Mustermann::Rails.new('/:1a/') }.
        to raise_error(Mustermann::CompileError, "capture name must start with underscore or lower case letter: \"/:1a/\"")
    end

    example 'same name twice' do
      expect { Mustermann::Rails.new('/:foo(/:bar)/:bar') }.
        to raise_error(Mustermann::CompileError, "can't use the same capture name twice: \"/:foo(/:bar)/:bar\"")
    end
  end

  context 'Regexp compatibility' do
    describe :=== do
      example('non-matching') { Mustermann::Rails.new("/")     .should_not be === '/foo' }
      example('matching')     { Mustermann::Rails.new("/:foo") .should     be === '/foo' }
    end

    describe :=~ do
      example('non-matching') { Mustermann::Rails.new("/")     .should_not be =~ '/foo' }
      example('matching')     { Mustermann::Rails.new("/:foo") .should     be =~ '/foo' }

      context 'String#=~' do
        example('non-matching') { "/foo".should_not be =~ Mustermann::Rails.new("/") }
        example('matching')     { "/foo".should     be =~ Mustermann::Rails.new("/:foo") }
      end
    end

    describe :to_regexp do
      example('empty pattern') { Mustermann::Rails.new('').to_regexp.should be == /\A(?-mix:)\Z/ }

      context 'Regexp.try_convert' do
        example('empty pattern') { Regexp.try_convert(Mustermann::Rails.new('')).should be == /\A(?-mix:)\Z/ }
      end
    end
  end

  context 'Proc compatibility' do
    describe :to_proc do
      example { Mustermann::Rails.new("/").to_proc.should be_a(Proc) }
      example('non-matching') { Mustermann::Rails.new("/")     .to_proc.call('/foo').should be == false }
      example('matching')     { Mustermann::Rails.new("/:foo") .to_proc.call('/foo').should be == true  }
    end
  end

  context "peeking" do
    subject(:pattern) { Mustermann::Rails.new(":name") }

    describe :peek_size do
      example { pattern.peek_size("foo bar/blah")   .should be == "foo bar".size }
      example { pattern.peek_size("foo%20bar/blah") .should be == "foo%20bar".size }
      example { pattern.peek_size("/foo bar")       .should be_nil }
    end

    describe :peek_match do
      example { pattern.peek_match("foo bar/blah")   .to_s .should be == "foo bar" }
      example { pattern.peek_match("foo%20bar/blah") .to_s .should be == "foo%20bar" }
      example { pattern.peek_match("/foo bar")             .should be_nil }
    end

    describe :peek_params do
      example { pattern.peek_params("foo bar/blah")   .should be == [{"name" => "foo bar"}, "foo bar".size] }
      example { pattern.peek_params("foo%20bar/blah") .should be == [{"name" => "foo bar"}, "foo%20bar".size] }
      example { pattern.peek_params("/foo bar")       .should be_nil }
    end
  end

  context 'version compatibility' do
    context '2.3' do
      pattern '(foo)', version: '2.3' do
        it { should_not match("")      }
        it { should_not match("foo")   }
        it { should     match("(foo)") }
      end

      pattern '\\:name', version: '2.3' do
        it { should match('%5cfoo').capturing(name: 'foo') }
      end
    end

    context '3.0' do
      pattern '(foo)', version: '3.0' do
        it { should match("")      }
        it { should match("foo")   }
      end

      pattern '\\:name', version: '3.0' do
        it { should     match(':name') }
        it { should_not match(':foo')  }
      end
    end

    context '3.2' do
      pattern '\\:name', version: '3.2' do
        it { should match('%5cfoo').capturing(name: 'foo') }
      end
    end

    context '4.0' do
      pattern '\\:name', version: '4.0' do
        it { should match('foo').capturing(name: 'foo') }
      end
    end

    context '4.2' do
      pattern '\\:name', version: '4.2' do
        it { should     match(':name') }
        it { should_not match(':foo')  }
      end
    end

    context '5.0' do
      pattern 'foo|bar', version: '5.0' do
        it { should match('foo') }
        it { should match('bar') }
      end
    end
  end
end
