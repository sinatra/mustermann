# frozen_string_literal: true
require 'support'
require 'mustermann/template'

describe Mustermann::Template do
  extend Support::Pattern

  pattern '' do
    it { should     match('')  }
    it { should_not match('/') }

    it { should respond_to(:expand)       }
    it { should respond_to(:to_templates) }
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
    it { should     match('/:foo')    }
    it { should     match('/%3Afoo')  }
    it { should_not match('/foo')     }
    it { should_not match('/foo?')    }
    it { should_not match('/foo/bar') }
    it { should_not match('/')        }
    it { should_not match('/foo/')    }
  end

  pattern '/föö' do
    it { should match("/f%C3%B6%C3%B6") }
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

  pattern '/test.bar' do
    it { should     match('/test.bar') }
    it { should_not match('/test0bar') }
  end

  pattern "/path with spaces", space_matches_plus: false do
    it { should     match('/path%20with%20spaces') }
    it { should_not match('/path%2Bwith%2Bspaces') }
    it { should_not match('/path+with+spaces')     }
  end

  pattern "/path with spaces", uri_decode: false do
    it { should_not match('/path%20with%20spaces') }
    it { should_not match('/path%2Bwith%2Bspaces') }
    it { should_not match('/path+with+spaces')     }
  end

  context 'level 1' do
    context 'without operator' do
      pattern '/hello/{person}' do
        it { should match('/hello/Frank').capturing person: 'Frank' }
        it { should match('/hello/a_b~c').capturing person: 'a_b~c' }
        it { should match('/hello/a.%20').capturing person: 'a.%20' }

        it { should_not match('/hello/:') }
        it { should_not match('/hello//') }
        it { should_not match('/hello/?') }
        it { should_not match('/hello/#') }
        it { should_not match('/hello/[') }
        it { should_not match('/hello/]') }
        it { should_not match('/hello/@') }
        it { should_not match('/hello/!') }
        it { should_not match('/hello/*') }
        it { should_not match('/hello/+') }
        it { should_not match('/hello/,') }
        it { should_not match('/hello/;') }
        it { should_not match('/hello/=') }

        example { pattern.params('/hello/Frank').should be == {'person' => 'Frank'} }
      end

      pattern "/{foo}/{bar}" do
        it { should match('/foo/bar')         .capturing foo: 'foo',     bar: 'bar'     }
        it { should match('/foo.bar/bar.foo') .capturing foo: 'foo.bar', bar: 'bar.foo' }
        it { should match('/10.1/te.st')      .capturing foo: '10.1',    bar: 'te.st'   }
        it { should match('/10.1.2/te.st')    .capturing foo: '10.1.2',  bar: 'te.st'   }

        it { should_not match('/foo%2Fbar') }
        it { should_not match('/foo%2fbar') }
      end
    end
  end

  context 'level 2' do
    context 'operator +' do
      pattern '/hello/{+person}' do
        it { should match('/hello/Frank') .capturing person: 'Frank' }
        it { should match('/hello/a_b~c') .capturing person: 'a_b~c' }
        it { should match('/hello/a.%20') .capturing person: 'a.%20' }
        it { should match('/hello/a/%20') .capturing person: 'a/%20' }
        it { should match('/hello/:')     .capturing person: ?:      }
        it { should match('/hello//')     .capturing person: ?/      }
        it { should match('/hello/?')     .capturing person: ??      }
        it { should match('/hello/#')     .capturing person: ?#      }
        it { should match('/hello/[')     .capturing person: ?[      }
        it { should match('/hello/]')     .capturing person: ?]      }
        it { should match('/hello/@')     .capturing person: ?@      }
        it { should match('/hello/!')     .capturing person: ?!      }
        it { should match('/hello/*')     .capturing person: ?*      }
        it { should match('/hello/+')     .capturing person: ?+      }
        it { should match('/hello/,')     .capturing person: ?,      }
        it { should match('/hello/;')     .capturing person: ?;      }
        it { should match('/hello/=')     .capturing person: ?=      }
      end

      pattern "/{+foo}/{bar}" do
        it { should match('/foo/bar')         .capturing foo: 'foo',     bar: 'bar'     }
        it { should match('/foo.bar/bar.foo') .capturing foo: 'foo.bar', bar: 'bar.foo' }
        it { should match('/foo/bar/bar.foo') .capturing foo: 'foo/bar', bar: 'bar.foo' }
        it { should match('/10.1/te.st')      .capturing foo: '10.1',    bar: 'te.st'   }
        it { should match('/10.1.2/te.st')    .capturing foo: '10.1.2',  bar: 'te.st'   }

        it { should_not match('/foo%2Fbar') }
        it { should_not match('/foo%2fbar') }
      end
    end

    context 'operator #' do
      pattern '/hello/{#person}' do
        it { should match('/hello/#Frank') .capturing person: 'Frank' }
        it { should match('/hello/#a_b~c') .capturing person: 'a_b~c' }
        it { should match('/hello/#a.%20') .capturing person: 'a.%20' }
        it { should match('/hello/#a/%20') .capturing person: 'a/%20' }
        it { should match('/hello/#:')     .capturing person: ?:      }
        it { should match('/hello/#/')     .capturing person: ?/      }
        it { should match('/hello/#?')     .capturing person: ??      }
        it { should match('/hello/##')     .capturing person: ?#      }
        it { should match('/hello/#[')     .capturing person: ?[      }
        it { should match('/hello/#]')     .capturing person: ?]      }
        it { should match('/hello/#@')     .capturing person: ?@      }
        it { should match('/hello/#!')     .capturing person: ?!      }
        it { should match('/hello/#*')     .capturing person: ?*      }
        it { should match('/hello/#+')     .capturing person: ?+      }
        it { should match('/hello/#,')     .capturing person: ?,      }
        it { should match('/hello/#;')     .capturing person: ?;      }
        it { should match('/hello/#=')     .capturing person: ?=      }


        it { should_not match('/hello/Frank') }
        it { should_not match('/hello/a_b~c') }
        it { should_not match('/hello/a.%20') }

        it { should_not match('/hello/:') }
        it { should_not match('/hello//') }
        it { should_not match('/hello/?') }
        it { should_not match('/hello/#') }
        it { should_not match('/hello/[') }
        it { should_not match('/hello/]') }
        it { should_not match('/hello/@') }
        it { should_not match('/hello/!') }
        it { should_not match('/hello/*') }
        it { should_not match('/hello/+') }
        it { should_not match('/hello/,') }
        it { should_not match('/hello/;') }
        it { should_not match('/hello/=') }


        example { pattern.params('/hello/#Frank').should be == {'person' => 'Frank'} }
      end

      pattern "/{+foo}/{#bar}" do
        it { should match('/foo/#bar')         .capturing foo: 'foo',     bar: 'bar'     }
        it { should match('/foo.bar/#bar.foo') .capturing foo: 'foo.bar', bar: 'bar.foo' }
        it { should match('/foo/bar/#bar.foo') .capturing foo: 'foo/bar', bar: 'bar.foo' }
        it { should match('/10.1/#te.st')      .capturing foo: '10.1',    bar: 'te.st'   }
        it { should match('/10.1.2/#te.st')    .capturing foo: '10.1.2',  bar: 'te.st'   }

        it { should_not match('/foo%2F#bar') }
        it { should_not match('/foo%2f#bar') }

        example { pattern.params('/hello/#Frank').should be == {'foo' => 'hello', 'bar' => 'Frank'} }
      end
    end
  end

  context 'level 3' do
    context 'without operator' do
      pattern "{a,b,c}" do
        it { should match("~x,42,_").capturing a: '~x', b: '42', c: '_' }
        it { should_not match("~x,42")      }
        it { should_not match("~x/42")      }
        it { should_not match("~x#42")      }
        it { should_not match("~x,42,_#42") }

        example { pattern.params('d,f,g').should be == {'a' => 'd', 'b' => 'f', 'c' => 'g'} }
      end
    end

    context 'operator +' do
      pattern "{+a,b,c}" do
        it { should match("~x,42,_")     .capturing a: '~x', b: '42', c: '_'     }
        it { should match("~x,42,_#42")  .capturing a: '~x', b: '42', c: '_#42'  }
        it { should match("~/x,42,_/42") .capturing a: '~/x', b: '42', c: '_/42' }

        it { should_not match("~x,42")      }
        it { should_not match("~x/42")      }
        it { should_not match("~x#42")      }
      end
    end

    context 'operator #' do
      pattern "{#a,b,c}" do
        it { should match("#~x,42,_")     .capturing a: '~x', b: '42', c: '_'     }
        it { should match("#~x,42,_#42")  .capturing a: '~x', b: '42', c: '_#42'  }
        it { should match("#~/x,42,_#42") .capturing a: '~/x', b: '42', c: '_#42' }

        it { should_not match("~x,42,_")     }
        it { should_not match("~x,42,_#42")  }
        it { should_not match("~/x,42,_#42") }

        it { should_not match("~x,42")      }
        it { should_not match("~x/42")      }
        it { should_not match("~x#42")      }
      end
    end

    context 'operator .' do
      pattern '/hello/{.person}' do
        it { should match('/hello/.Frank') .capturing person: 'Frank' }
        it { should match('/hello/.a_b~c') .capturing person: 'a_b~c' }

        it { should_not match('/hello/.:') }
        it { should_not match('/hello/./') }
        it { should_not match('/hello/.?') }
        it { should_not match('/hello/.#') }
        it { should_not match('/hello/.[') }
        it { should_not match('/hello/.]') }
        it { should_not match('/hello/.@') }
        it { should_not match('/hello/.!') }
        it { should_not match('/hello/.*') }
        it { should_not match('/hello/.+') }
        it { should_not match('/hello/.,') }
        it { should_not match('/hello/.;') }
        it { should_not match('/hello/.=') }

        it { should_not match('/hello/Frank')  }
        it { should_not match('/hello/a_b~c')  }
        it { should_not match('/hello/a.%20')  }

        it { should_not match('/hello/:') }
        it { should_not match('/hello//') }
        it { should_not match('/hello/?') }
        it { should_not match('/hello/#') }
        it { should_not match('/hello/[') }
        it { should_not match('/hello/]') }
        it { should_not match('/hello/@') }
        it { should_not match('/hello/!') }
        it { should_not match('/hello/*') }
        it { should_not match('/hello/+') }
        it { should_not match('/hello/,') }
        it { should_not match('/hello/;') }
        it { should_not match('/hello/=') }
      end

      pattern "{.a,b,c}" do
        it { should match(".~x.42._").capturing a: '~x', b: '42', c: '_' }
        it { should_not match(".~x,42")   }
        it { should_not match(".~x/42")   }
        it { should_not match(".~x#42")   }
        it { should_not match(".~x,42,_") }
        it { should_not match("~x.42._")  }
      end
    end

    context 'operator /' do
      pattern '/hello{/person}' do
        it { should match('/hello/Frank') .capturing person: 'Frank' }
        it { should match('/hello/a_b~c') .capturing person: 'a_b~c' }

        it { should_not match('/hello//:') }
        it { should_not match('/hello///') }
        it { should_not match('/hello//?') }
        it { should_not match('/hello//#') }
        it { should_not match('/hello//[') }
        it { should_not match('/hello//]') }
        it { should_not match('/hello//@') }
        it { should_not match('/hello//!') }
        it { should_not match('/hello//*') }
        it { should_not match('/hello//+') }
        it { should_not match('/hello//,') }
        it { should_not match('/hello//;') }
        it { should_not match('/hello//=') }

        it { should_not match('/hello/:') }
        it { should_not match('/hello//') }
        it { should_not match('/hello/?') }
        it { should_not match('/hello/#') }
        it { should_not match('/hello/[') }
        it { should_not match('/hello/]') }
        it { should_not match('/hello/@') }
        it { should_not match('/hello/!') }
        it { should_not match('/hello/*') }
        it { should_not match('/hello/+') }
        it { should_not match('/hello/,') }
        it { should_not match('/hello/;') }
        it { should_not match('/hello/=') }
      end

      pattern "{/a,b,c}" do
        it { should match("/~x/42/_").capturing a: '~x', b: '42', c: '_' }
        it { should_not match("/~x,42")   }
        it { should_not match("/~x.42")   }
        it { should_not match("/~x#42")   }
        it { should_not match("/~x,42,_") }
        it { should_not match("~x/42/_")  }
      end
    end

    context 'operator ;' do
      pattern '/hello/{;person}' do
        it { should match('/hello/;person=Frank') .capturing person: 'Frank' }
        it { should match('/hello/;person=a_b~c') .capturing person: 'a_b~c' }
        it { should match('/hello/;person')       .capturing person: nil     }

        it { should_not match('/hello/;persona=Frank') }
        it { should_not match('/hello/;persona=a_b~c') }

        it { should_not match('/hello/;person=:') }
        it { should_not match('/hello/;person=/') }
        it { should_not match('/hello/;person=?') }
        it { should_not match('/hello/;person=#') }
        it { should_not match('/hello/;person=[') }
        it { should_not match('/hello/;person=]') }
        it { should_not match('/hello/;person=@') }
        it { should_not match('/hello/;person=!') }
        it { should_not match('/hello/;person=*') }
        it { should_not match('/hello/;person=+') }
        it { should_not match('/hello/;person=,') }
        it { should_not match('/hello/;person=;') }
        it { should_not match('/hello/;person==') }

        it { should_not match('/hello/;Frank')  }
        it { should_not match('/hello/;a_b~c')  }
        it { should_not match('/hello/;a.%20')  }

        it { should_not match('/hello/:') }
        it { should_not match('/hello//') }
        it { should_not match('/hello/?') }
        it { should_not match('/hello/#') }
        it { should_not match('/hello/[') }
        it { should_not match('/hello/]') }
        it { should_not match('/hello/@') }
        it { should_not match('/hello/!') }
        it { should_not match('/hello/*') }
        it { should_not match('/hello/+') }
        it { should_not match('/hello/,') }
        it { should_not match('/hello/;') }
        it { should_not match('/hello/=') }
      end

      pattern "{;a,b,c}" do
        it { should match(";a=~x;b=42;c=_") .capturing a: '~x', b: '42', c: '_' }
        it { should match(";a=~x;b;c=_")    .capturing a: '~x', b: nil,  c: '_' }

        it { should_not match(";a=~x;c=_;b=42").capturing a: '~x', b: '42', c: '_' }

        it { should_not match(";a=~x;b=42")     }
        it { should_not match("a=~x;b=42")      }
        it { should_not match(";a=~x;b=#42;c")  }
        it { should_not match(";a=~x,b=42,c=_") }
        it { should_not match("~x;b=42;c=_")    }
      end
    end

    context 'operator ?' do
      pattern '/hello/{?person}' do
        it { should match('/hello/?person=Frank') .capturing person: 'Frank' }
        it { should match('/hello/?person=a_b~c') .capturing person: 'a_b~c' }
        it { should match('/hello/?person')       .capturing person: nil     }

        it { should_not match('/hello/?persona=Frank') }
        it { should_not match('/hello/?persona=a_b~c') }

        it { should_not match('/hello/?person=:') }
        it { should_not match('/hello/?person=/') }
        it { should_not match('/hello/?person=?') }
        it { should_not match('/hello/?person=#') }
        it { should_not match('/hello/?person=[') }
        it { should_not match('/hello/?person=]') }
        it { should_not match('/hello/?person=@') }
        it { should_not match('/hello/?person=!') }
        it { should_not match('/hello/?person=*') }
        it { should_not match('/hello/?person=+') }
        it { should_not match('/hello/?person=,') }
        it { should_not match('/hello/?person=;') }
        it { should_not match('/hello/?person==') }

        it { should_not match('/hello/?Frank')  }
        it { should_not match('/hello/?a_b~c')  }
        it { should_not match('/hello/?a.%20')  }

        it { should_not match('/hello/:') }
        it { should_not match('/hello//') }
        it { should_not match('/hello/?') }
        it { should_not match('/hello/#') }
        it { should_not match('/hello/[') }
        it { should_not match('/hello/]') }
        it { should_not match('/hello/@') }
        it { should_not match('/hello/!') }
        it { should_not match('/hello/*') }
        it { should_not match('/hello/+') }
        it { should_not match('/hello/,') }
        it { should_not match('/hello/;') }
        it { should_not match('/hello/=') }
      end

      pattern "{?a,b,c}" do
        it { should match("?a=~x&b=42&c=_") .capturing a: '~x', b: '42', c: '_' }
        it { should match("?a=~x&b&c=_")    .capturing a: '~x', b: nil,  c: '_' }

        it { should_not match("?a=~x&c=_&b=42").capturing a: '~x', b: '42', c: '_' }

        it { should_not match("?a=~x&b=42")     }
        it { should_not match("a=~x&b=42")      }
        it { should_not match("?a=~x&b=#42&c")  }
        it { should_not match("?a=~x,b=42,c=_") }
        it { should_not match("~x&b=42&c=_")    }
      end
    end

    context 'operator &' do
      pattern '/hello/{&person}' do
        it { should match('/hello/&person=Frank') .capturing person: 'Frank' }
        it { should match('/hello/&person=a_b~c') .capturing person: 'a_b~c' }
        it { should match('/hello/&person')       .capturing person: nil     }

        it { should_not match('/hello/&persona=Frank') }
        it { should_not match('/hello/&persona=a_b~c') }

        it { should_not match('/hello/&person=:') }
        it { should_not match('/hello/&person=/') }
        it { should_not match('/hello/&person=?') }
        it { should_not match('/hello/&person=#') }
        it { should_not match('/hello/&person=[') }
        it { should_not match('/hello/&person=]') }
        it { should_not match('/hello/&person=@') }
        it { should_not match('/hello/&person=!') }
        it { should_not match('/hello/&person=*') }
        it { should_not match('/hello/&person=+') }
        it { should_not match('/hello/&person=,') }
        it { should_not match('/hello/&person=;') }
        it { should_not match('/hello/&person==') }

        it { should_not match('/hello/&Frank')  }
        it { should_not match('/hello/&a_b~c')  }
        it { should_not match('/hello/&a.%20')  }

        it { should_not match('/hello/:') }
        it { should_not match('/hello//') }
        it { should_not match('/hello/?') }
        it { should_not match('/hello/#') }
        it { should_not match('/hello/[') }
        it { should_not match('/hello/]') }
        it { should_not match('/hello/@') }
        it { should_not match('/hello/!') }
        it { should_not match('/hello/*') }
        it { should_not match('/hello/+') }
        it { should_not match('/hello/,') }
        it { should_not match('/hello/;') }
        it { should_not match('/hello/=') }
      end

      pattern "{&a,b,c}" do
        it { should match("&a=~x&b=42&c=_") .capturing a: '~x', b: '42', c: '_' }
        it { should match("&a=~x&b&c=_")    .capturing a: '~x', b: nil,  c: '_' }

        it { should_not match("&a=~x&c=_&b=42").capturing a: '~x', b: '42', c: '_' }

        it { should_not match("&a=~x&b=42")     }
        it { should_not match("a=~x&b=42")      }
        it { should_not match("&a=~x&b=#42&c")  }
        it { should_not match("&a=~x,b=42,c=_") }
        it { should_not match("~x&b=42&c=_")    }
      end
    end
  end

  context 'level 4' do
    context 'without operator' do
      context 'prefix' do
        pattern '{a:3}/bar' do
          it { should match('foo/bar') .capturing a: 'foo' }
          it { should match('fo/bar')  .capturing a: 'fo'  }
          it { should match('f/bar')   .capturing a: 'f'   }
          it { should_not match('fooo/bar') }
        end

        pattern '{a:3}{b}' do
          it { should match('foobar') .capturing a: 'foo', b: 'bar' }
        end
      end

      context 'expand' do
        pattern '{a*}' do
          it { should match('a')     .capturing a: 'a'     }
          it { should match('a,b')   .capturing a: 'a,b'   }
          it { should match('a,b,c') .capturing a: 'a,b,c' }
          it { should_not match('a,b/c') }
          it { should_not match('a,') }

          example { pattern.params('a').should be == { 'a' => ['a'] }}
          example { pattern.params('a,b').should be == { 'a' => ['a', 'b'] }}
        end

        pattern '{a*},{b}' do
          it { should match('a,b')   .capturing a: 'a',   b: 'b' }
          it { should match('a,b,c') .capturing a: 'a,b', b: 'c' }
          it { should_not match('a,b/c') }
          it { should_not match('a,') }

          example { pattern.params('a,b').should be == { 'a' => ['a'], 'b' => 'b' }}
          example { pattern.params('a,b,c').should be == { 'a' => ['a', 'b'], 'b' => 'c' }}
        end

        pattern '{a*,b}' do
          it { should match('a,b')   .capturing a: 'a',   b: 'b' }
          it { should match('a,b,c') .capturing a: 'a,b', b: 'c' }
          it { should_not match('a,b/c') }
          it { should_not match('a,') }

          example { pattern.params('a,b').should be == { 'a' => ['a'], 'b' => 'b' }}
          example { pattern.params('a,b,c').should be == { 'a' => ['a', 'b'], 'b' => 'c' }}
        end
      end
    end

    context 'operator +' do
      pattern '/{a}/{+b}' do
        it { should match('/foo/bar/baz').capturing(a: 'foo', b: 'bar/baz') }
        it { should expand(a: 'foo/bar', b: 'foo/bar').to('/foo%2Fbar/foo/bar') }
      end

      context 'prefix' do
        pattern '{+a:3}/bar' do
          it { should match('foo/bar') .capturing a: 'foo' }
          it { should match('fo/bar')  .capturing a: 'fo'  }
          it { should match('f/bar')   .capturing a: 'f'   }
          it { should_not match('fooo/bar') }
        end

        pattern '{+a:3}{b}' do
          it { should match('foobar') .capturing a: 'foo', b: 'bar' }
        end
      end

      context 'expand' do
        pattern '{+a*}' do
          it { should match('a')     .capturing a: 'a'     }
          it { should match('a,b')   .capturing a: 'a,b'   }
          it { should match('a,b,c') .capturing a: 'a,b,c' }
          it { should match('a,b/c') .capturing a: 'a,b/c' }
        end

        pattern '{+a*},{b}' do
          it { should match('a,b')   .capturing a: 'a',   b: 'b' }
          it { should match('a,b,c') .capturing a: 'a,b', b: 'c' }
          it { should_not match('a,b/c') }
          it { should_not match('a,') }

          example { pattern.params('a,b').should be == { 'a' => ['a'], 'b' => 'b' }}
          example { pattern.params('a,b,c').should be == { 'a' => ['a', 'b'], 'b' => 'c' }}
        end
      end
    end

    context 'operator #' do
      context 'prefix' do
        pattern '{#a:3}/bar' do
          it { should match('#foo/bar') .capturing a: 'foo' }
          it { should match('#fo/bar')  .capturing a: 'fo'  }
          it { should match('#f/bar')   .capturing a: 'f'   }
          it { should_not match('#fooo/bar') }
        end

        pattern '{#a:3}{b}' do
          it { should match('#foobar') .capturing a: 'foo', b: 'bar' }
        end
      end

      context 'expand' do
        pattern '{#a*}' do
          it { should match('#a')     .capturing a: 'a'     }
          it { should match('#a,b')   .capturing a: 'a,b'   }
          it { should match('#a,b,c') .capturing a: 'a,b,c' }
          it { should match('#a,b/c') .capturing a: 'a,b/c' }

          example { pattern.params('#a,b').should be == { 'a' => ['a', 'b'] }}
          example { pattern.params('#a,b,c').should be == { 'a' => ['a', 'b', 'c'] }}
        end

        pattern '{#a*,b}' do
          it { should match('#a,b')   .capturing a: 'a',   b: 'b' }
          it { should match('#a,b,c') .capturing a: 'a,b', b: 'c' }
          it { should_not match('#a,') }

          example { pattern.params('#a,b').should be == { 'a' => ['a'], 'b' => 'b' }}
          example { pattern.params('#a,b,c').should be == { 'a' => ['a', 'b'], 'b' => 'c' }}
        end
      end
    end

    context 'operator .' do
      context 'prefix' do
        pattern '{.a:3}/bar' do
          it { should match('.foo/bar') .capturing a: 'foo' }
          it { should match('.fo/bar')  .capturing a: 'fo'  }
          it { should match('.f/bar')   .capturing a: 'f'   }
          it { should_not match('.fooo/bar') }
        end

        pattern '{.a:3}{b}' do
          it { should match('.foobar') .capturing a: 'foo', b: 'bar' }
        end
      end

      context 'expand' do
        pattern '{.a*}' do
          it { should match('.a')     .capturing a: 'a'     }
          it { should match('.a.b')   .capturing a: 'a.b'   }
          it { should match('.a.b.c') .capturing a: 'a.b.c' }
          it { should_not match('.a.b,c') }
          it { should_not match('.a,') }
        end

        pattern '{.a*,b}' do
          it { should match('.a.b')   .capturing a: 'a',   b: 'b' }
          it { should match('.a.b.c') .capturing a: 'a.b', b: 'c' }
          it { should_not match('.a.b/c') }
          it { should_not match('.a.') }

          example { pattern.params('.a.b').should be == { 'a' => ['a'], 'b' => 'b' }}
          example { pattern.params('.a.b.c').should be == { 'a' => ['a', 'b'], 'b' => 'c' }}
        end
      end
    end

    context 'operator /' do
      context 'prefix' do
        pattern '{/a:3}/bar' do
          it { should match('/foo/bar') .capturing a: 'foo' }
          it { should match('/fo/bar')  .capturing a: 'fo'  }
          it { should match('/f/bar')   .capturing a: 'f'   }
          it { should_not match('/fooo/bar') }
        end

        pattern '{/a:3}{b}' do
          it { should match('/foobar') .capturing a: 'foo', b: 'bar' }
        end
      end

      context 'expand' do
        pattern '{/a*}' do
          it { should match('/a')     .capturing a: 'a'     }
          it { should match('/a/b')   .capturing a: 'a/b'   }
          it { should match('/a/b/c') .capturing a: 'a/b/c' }
          it { should_not match('/a/b,c') }
          it { should_not match('/a,') }
        end

        pattern '{/a*,b}' do
          it { should match('/a/b')   .capturing a: 'a',   b: 'b' }
          it { should match('/a/b/c') .capturing a: 'a/b', b: 'c' }
          it { should_not match('/a/b,c') }
          it { should_not match('/a/') }

          example { pattern.params('/a/b').should be == { 'a' => ['a'], 'b' => 'b' }}
          example { pattern.params('/a/b/c').should be == { 'a' => ['a', 'b'], 'b' => 'c' }}
        end
      end
    end

    context 'operator ;' do
      context 'prefix' do
        pattern '{;a:3}/bar' do
          it { should match(';a=foo/bar') .capturing a: 'foo' }
          it { should match(';a=fo/bar')  .capturing a: 'fo'  }
          it { should match(';a=f/bar')   .capturing a: 'f'   }
          it { should_not match(';a=fooo/bar') }
        end

        pattern '{;a:3}{b}' do
          it { should match(';a=foobar') .capturing a: 'foo', b: 'bar' }
        end
      end

      context 'expand' do
        pattern '{;a*}' do
          it { should match(';a=1')         .capturing a: 'a=1'         }
          it { should match(';a=1;a=2')     .capturing a: 'a=1;a=2'     }
          it { should match(';a=1;a=2;a=3') .capturing a: 'a=1;a=2;a=3' }
          it { should_not match(';a=1;a=2;b=3') }
          it { should_not match(';a=1;a=2;a=3,') }
        end

        pattern '{;a*,b}' do
          it { should match(';a=1;b')       .capturing a: 'a=1',     b: nil }
          it { should match(';a=2;a=2;b=1') .capturing a: 'a=2;a=2', b: '1' }
          it { should_not match(';a;b;c') }
          it { should_not match(';a;') }

          example { pattern.params(';a=2;a=2;b').should be == { 'a' => ['2', '2'], 'b' => nil }}
        end
      end
    end

    context 'operator ?' do
      context 'prefix' do
        pattern '{?a:3}/bar' do
          it { should match('?a=foo/bar') .capturing a: 'foo' }
          it { should match('?a=fo/bar')  .capturing a: 'fo'  }
          it { should match('?a=f/bar')   .capturing a: 'f'   }
          it { should_not match('?a=fooo/bar') }
        end

        pattern '{?a:3}{b}' do
          it { should match('?a=foobar') .capturing a: 'foo', b: 'bar' }
        end
      end

      context 'expand' do
        pattern '{?a*}' do
          it { should match('?a=1')         .capturing a: 'a=1'         }
          it { should match('?a=1&a=2')     .capturing a: 'a=1&a=2'     }
          it { should match('?a=1&a=2&a=3') .capturing a: 'a=1&a=2&a=3' }
          it { should_not match('?a=1&a=2&b=3') }
          it { should_not match('?a=1&a=2&a=3,') }
        end

        pattern '{?a*,b}' do
          it { should match('?a=1&b')       .capturing a: 'a=1',     b: nil }
          it { should match('?a=2&a=2&b=1') .capturing a: 'a=2&a=2', b: '1' }
          it { should_not match('?a&b&c') }
          it { should_not match('?a&') }

          example { pattern.params('?a=2&a=2&b').should be == { 'a' => ['2', '2'], 'b' => nil }}
        end
      end
    end

    context 'operator &' do
      context 'prefix' do
        pattern '{&a:3}/bar' do
          it { should match('&a=foo/bar') .capturing a: 'foo' }
          it { should match('&a=fo/bar')  .capturing a: 'fo'  }
          it { should match('&a=f/bar')   .capturing a: 'f'   }
          it { should_not match('&a=fooo/bar') }
        end

        pattern '{&a:3}{b}' do
          it { should match('&a=foobar') .capturing a: 'foo', b: 'bar' }
        end
      end

      context 'expand' do
        pattern '{&a*}' do
          it { should match('&a=1')         .capturing a: 'a=1'         }
          it { should match('&a=1&a=2')     .capturing a: 'a=1&a=2'     }
          it { should match('&a=1&a=2&a=3') .capturing a: 'a=1&a=2&a=3' }
          it { should_not match('&a=1&a=2&b=3') }
          it { should_not match('&a=1&a=2&a=3,') }
        end

        pattern '{&a*,b}' do
          it { should match('&a=1&b')       .capturing a: 'a=1',     b: nil }
          it { should match('&a=2&a=2&b=1') .capturing a: 'a=2&a=2', b: '1' }
          it { should_not match('&a&b&c') }
          it { should_not match('&a&') }

          example { pattern.params('&a=2&a=2&b').should be == { 'a' => ['2', '2'], 'b' => nil }}
          example { pattern.params('&a=2&a=%20&b').should be == { 'a' => ['2', ' '], 'b' => nil }}
        end
      end
    end
  end

  context 'invalid syntax' do
    example 'unexpected closing bracket' do
      expect { Mustermann::Template.new('foo}bar') }.
        to raise_error(Mustermann::ParseError, 'unexpected } while parsing "foo}bar"')
    end

    example 'missing closing bracket' do
      expect { Mustermann::Template.new('foo{bar') }.
        to raise_error(Mustermann::ParseError, 'unexpected end of string while parsing "foo{bar"')
    end
  end

  context "peeking" do
    subject(:pattern) { Mustermann::Template.new("{name}bar") }

    describe :peek_size do
      example { pattern.peek_size("foo%20bar/blah") .should be == "foo%20bar".size }
      example { pattern.peek_size("/foo bar")       .should be_nil }
    end

    describe :peek_match do
      example { pattern.peek_match("foo%20bar/blah") .to_s .should be == "foo%20bar" }
      example { pattern.peek_match("/foo bar")             .should be_nil }
    end

    describe :peek_params do
      example { pattern.peek_params("foo%20bar/blah") .should be == [{"name" => "foo "}, "foo%20bar".size] }
      example { pattern.peek_params("/foo bar")       .should be_nil }
    end
  end
end
