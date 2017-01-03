# frozen_string_literal: true
require 'support'
require 'mustermann/simple'
require 'mustermann/visualizer'

describe Mustermann::Simple do
  extend Support::Pattern

  pattern '' do
    it { should     match('')  }
    it { should_not match('/') }

    it { should_not respond_to(:expand)       }
    it { should_not respond_to(:to_templates) }
  end

  pattern '/' do
    it { should     match('/')    }
    it { should_not match('/foo') }
  end

  pattern '/foo' do
    it { should     match('/foo')     }
    it { should_not match('/bar')     }
    it { should_not match('/foo.bar') }
  end

  pattern '/foo/bar' do
    it { should     match('/foo/bar')   }
    it { should_not match('/foo%2Fbar') }
    it { should_not match('/foo%2fbar') }
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
  end

  pattern '/föö' do
    it { should match("/f%C3%B6%C3%B6") }
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
  end

  pattern '/hello/:person' do
    it { should match('/hello/Frank').capturing person: 'Frank' }
  end

  pattern '/?:foo?/?:bar?' do
    it { should match('/hello/world') .capturing foo: 'hello', bar: 'world' }
    it { should match('/hello')       .capturing foo: 'hello', bar: nil     }
    it { should match('/')            .capturing foo: nil,     bar: nil     }
    it { should match('')             .capturing foo: nil,     bar: nil     }

    it { should_not match('/hello/world/') }
  end

  pattern '/*' do
    it { should match('/')        .capturing splat: '' }
    it { should match('/foo')     .capturing splat: 'foo' }
    it { should match('/foo/bar') .capturing splat: 'foo/bar' }

    example { pattern.params('/foo').should be == {"splat" => ["foo"]} }
  end

  pattern '/:foo/*' do
    it { should match("/foo/bar/baz")     .capturing foo: 'foo',   splat: 'bar/baz'   }
    it { should match("/foo/")            .capturing foo: 'foo',   splat: ''          }
    it { should match('/h%20w/h%20a%20y') .capturing foo: 'h%20w', splat: 'h%20a%20y' }
    it { should_not match('/foo') }

    example { pattern.params('/bar/foo').should be == {"splat" => ["foo"], "foo" => "bar"} }
    example { pattern.params('/bar/foo/f%20o').should be == {"splat" => ["foo/f o"], "foo" => "bar"} }
  end

  pattern '/test$/' do
    it { should match('/test$/') }
  end

  pattern '/te+st/' do
    it { should     match('/te+st/') }
    it { should_not match('/test/')  }
    it { should_not match('/teest/') }
  end

  pattern "/path with spaces" do
    it { should match('/path%20with%20spaces') }
    it { should match('/path%2Bwith%2Bspaces') }
    it { should match('/path+with+spaces')     }
  end

  pattern '/foo&bar' do
    it { should match('/foo&bar') }
  end

  pattern '/*/:foo/*/*' do
    it { should match('/bar/foo/bling/baz/boom') }

    it "should capture all splat parts" do
      match = pattern.match('/bar/foo/bling/baz/boom')
      match.captures.should be == ['bar', 'foo', 'bling', 'baz/boom']
      match.names.should be == ['splat', 'foo']
    end

    it 'should map to proper params' do
      pattern.params('/bar/foo/bling/baz/boom').should be == {
        "foo" => "foo", "splat" => ['bar', 'bling', 'baz/boom']
      }
    end
  end

  pattern '/test.bar' do
    it { should     match('/test.bar') }
    it { should_not match('/test0bar') }
  end

  pattern '/:file.:ext' do
    it { should match('/pony.jpg')    .capturing file: 'pony', ext: 'jpg' }
    it { should match('/pony%2Ejpg') .capturing file: 'pony', ext: 'jpg' }
    it { should match('/pony%2ejpg') .capturing file: 'pony', ext: 'jpg' }

    it { should match('/pony%E6%AD%A3%2Ejpg') .capturing file: 'pony%E6%AD%A3', ext: 'jpg' }
    it { should match('/pony%e6%ad%a3%2ejpg') .capturing file: 'pony%e6%ad%a3', ext: 'jpg' }
    it { should match('/pony正%2Ejpg')        .capturing file: 'pony正',         ext: 'jpg' }
    it { should match('/pony正%2ejpg')        .capturing file: 'pony正',         ext: 'jpg' }
    it { should match('/pony正..jpg')         .capturing file: 'pony正.',        ext: 'jpg' }

    it { should_not match('/.jpg') }
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

  pattern '/foo?' do
    it { should     match('/fo')   }
    it { should     match('/foo')  }
    it { should_not match('')      }
    it { should_not match('/')     }
    it { should_not match('/f')    }
    it { should_not match('/fooo') }
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

  pattern '/:foo.?' do
    it { should match('/a.').capturing foo: 'a.' }
    it { should match('/xy').capturing foo: 'xy' }
  end

  pattern '/(a)' do
    it { should     match('/(a)') }
    it { should_not match('/a') }
  end

  pattern '/:foo.?', greedy: false do
    it { should match('/a.').capturing foo: 'a'  }
    it { should match('/xy').capturing foo: 'xy' }
  end

  pattern '/foo?', uri_decode: false do
    it { should     match('/foo')  }
    it { should     match('/fo')   }
    it { should_not match('/foo?') }
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

  context 'error handling' do
    example '? at beginning of route' do
      expect { Mustermann::Simple.new('?foobar') }.
        to raise_error(Mustermann::ParseError)
    end

    example 'invalid capture name' do
      expect { Mustermann::Simple.new('/:1a/') }.
        to raise_error(Mustermann::CompileError)
    end
  end

  context "peeking" do
    subject(:pattern) { Mustermann::Simple.new(":name") }

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

  context "highlighting" do
    let(:pattern) { Mustermann::Simple.new("/:name?/*") }
    subject(:sexp) { Mustermann::Visualizer.highlight(pattern).to_sexp }
    it { should be == "(root (separator /) (capture : (name name)) (optional ?) (separator /) (splat *))" }
  end
end
