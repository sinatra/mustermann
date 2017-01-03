# frozen_string_literal: true
require 'support'
require 'mustermann/flask'

describe Mustermann::Flask do
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

  pattern '/<foo>' do
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

  pattern '/<string:foo>' do
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

  pattern '/<string(minlength=2):foo>' do
    it { should match('/foo')       .capturing foo: 'foo'       }
    it { should match('/bar')       .capturing foo: 'bar'       }
    it { should match('/foo.bar')   .capturing foo: 'foo.bar'   }
    it { should match('/%0Afoo')    .capturing foo: '%0Afoo'    }
    it { should match('/foo%2Fbar') .capturing foo: 'foo%2Fbar' }

    it { should_not match('/f')       }
    it { should_not match('/foo?')    }
    it { should_not match('/foo/bar') }
    it { should_not match('/')        }
    it { should_not match('/foo/')    }

    it { should generate_template('/{foo}') }
  end

  pattern '/<string(maxlength=3):foo>' do
    it { should match('/f')   .capturing foo: 'f'   }
    it { should match('/fo')  .capturing foo: 'fo'  }
    it { should match('/foo') .capturing foo: 'foo' }
    it { should match('/bar') .capturing foo: 'bar' }

    it { should_not match('/fooo')    }
    it { should_not match('/foo.bar') }
    it { should_not match('/foo?')    }
    it { should_not match('/foo/bar') }
    it { should_not match('/')        }
    it { should_not match('/foo/')    }

    it { should generate_template('/{foo}') }
  end

  pattern '/<string(length=3):foo>' do
    it { should match('/foo') .capturing foo: 'foo' }
    it { should match('/bar') .capturing foo: 'bar' }

    it { should_not match('/f')       }
    it { should_not match('/fo')      }
    it { should_not match('/fooo')    }
    it { should_not match('/foo.bar') }
    it { should_not match('/foo?')    }
    it { should_not match('/foo/bar') }
    it { should_not match('/')        }
    it { should_not match('/foo/')    }

    it { should generate_template('/{foo}') }
  end

  pattern '/<int:foo>' do
    it { should match('/42').capturing foo: '42' }

    it { should_not match('/1.0')       }
    it { should_not match('/.5')        }
    it { should_not match('/foo')       }
    it { should_not match('/bar')       }
    it { should_not match('/foo.bar')   }
    it { should_not match('/%0Afoo')    }
    it { should_not match('/foo%2Fbar') }

    it { should_not match('/foo?')    }
    it { should_not match('/foo/bar') }
    it { should_not match('/')        }
    it { should_not match('/foo/')    }

    example { pattern.params('/42').should be == {"foo" => 42} }
    it { should expand(foo: 12).to('/12') }
    it { should generate_template('/{foo}') }
  end

  pattern '/<int:foo>' do
    it { should match('/42').capturing foo: '42' }

    it { should_not match('/1.0')       }
    it { should_not match('/.5')        }
    it { should_not match('/foo')       }
    it { should_not match('/bar')       }
    it { should_not match('/foo.bar')   }
    it { should_not match('/%0Afoo')    }
    it { should_not match('/foo%2Fbar') }

    it { should_not match('/foo?')    }
    it { should_not match('/foo/bar') }
    it { should_not match('/')        }
    it { should_not match('/foo/')    }

    example { pattern.params('/42').should be == {"foo" => 42} }
    it { should expand(foo: 12).to('/12') }
    it { should generate_template('/{foo}') }
  end

  pattern '/<any(foo,bar):foo>' do
    it { should match('/foo') .capturing foo: 'foo' }
    it { should match('/bar') .capturing foo: 'bar' }

    it { should_not match('/f')       }
    it { should_not match('/fo')      }
    it { should_not match('/fooo')    }
    it { should_not match('/foo.bar') }
    it { should_not match('/foo?')    }
    it { should_not match('/foo/bar') }
    it { should_not match('/')        }
    it { should_not match('/foo/')    }
    it { should_not match('/baz')     }

    it { should generate_template('/{foo}') }
  end

  pattern '/<any( foo, bar ):foo>' do
    it { should match('/foo') .capturing foo: 'foo' }
    it { should match('/bar') .capturing foo: 'bar' }

    it { should_not match('/f')       }
    it { should_not match('/fo')      }
    it { should_not match('/fooo')    }
    it { should_not match('/foo.bar') }
    it { should_not match('/foo?')    }
    it { should_not match('/foo/bar') }
    it { should_not match('/')        }
    it { should_not match('/foo/')    }
    it { should_not match('/baz')     }

    it { should generate_template('/{foo}') }
  end

  pattern '/<any(foo, bar, "foo,bar"):foo>' do
    it { should match('/foo')     .capturing foo: 'foo'      }
    it { should match('/bar')     .capturing foo: 'bar'      }
    it { should match('/foo,bar') .capturing foo: 'foo,bar' }

    it { should_not match('/f')       }
    it { should_not match('/fo')      }
    it { should_not match('/fooo')    }
    it { should_not match('/foo.bar') }
    it { should_not match('/foo?')    }
    it { should_not match('/foo/bar') }
    it { should_not match('/')        }
    it { should_not match('/foo/')    }
    it { should_not match('/baz')     }

    it { should generate_template('/{foo}') }
  end

  pattern '/<any(foo, bar, foo\,bar):foo>' do
    it { should match('/foo')     .capturing foo: 'foo'      }
    it { should match('/bar')     .capturing foo: 'bar'      }
    it { should match('/foo,bar') .capturing foo: 'foo,bar' }

    it { should_not match('/f')       }
    it { should_not match('/fo')      }
    it { should_not match('/fooo')    }
    it { should_not match('/foo.bar') }
    it { should_not match('/foo?')    }
    it { should_not match('/foo/bar') }
    it { should_not match('/')        }
    it { should_not match('/foo/')    }
    it { should_not match('/baz')     }

    it { should generate_template('/{foo}') }
  end

  pattern '/<any(foo, bar, "foo\,bar"):foo>' do
    it { should match('/foo')     .capturing foo: 'foo'      }
    it { should match('/bar')     .capturing foo: 'bar'      }
    it { should match('/foo,bar') .capturing foo: 'foo,bar' }

    it { should_not match('/f')       }
    it { should_not match('/fo')      }
    it { should_not match('/fooo')    }
    it { should_not match('/foo.bar') }
    it { should_not match('/foo?')    }
    it { should_not match('/foo/bar') }
    it { should_not match('/')        }
    it { should_not match('/foo/')    }
    it { should_not match('/baz')     }

    it { should generate_template('/{foo}') }
  end

  pattern '/<int(min=5,max=50):foo>' do
    example { pattern.params('/42').should be == {"foo" => 42} }
    example { pattern.params('/52').should be == {"foo" => 50} }
    example { pattern.params('/2').should  be == {"foo" =>  5} }
  end

  pattern '/<float(min=5,max=50.5):foo>' do
    example { pattern.params('/42.5').should be == {"foo" => 42.5} }
    example { pattern.params('/52.5').should be == {"foo" => 50.5} }
    example { pattern.params('/2.5').should  be == {"foo" =>  5.0} }
  end

  pattern '/<prefix>/<float:foo>/<int:bar>' do
    it { should match('/foo/42/42') .capturing foo: '42',  bar: '42'  }
    it { should match('/foo/1.0/1') .capturing foo: '1.0', bar: '1'   }
    it { should match('/foo/.5/0')  .capturing foo: '.5',  bar: '0'   }

    it { should_not match('/foo/1/1.0')   }
    it { should_not match('/foo/1.0/1.0') }

    it { should generate_template('/{prefix}/{foo}/{bar}') }

    example do
       pattern.params('/foo/1.0/1').should be == {
         "prefix" => "foo",
         "foo"    => 1.0,
         "bar"    => 1
       }
    end
  end

  pattern '/<path:foo>' do
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

  converter = Struct.new(:convert).new(:upcase.to_proc)
  pattern '/<foo:bar>', converters: { foo: converter } do
    it { should match('/foo').capturing bar: 'foo' }
    example { pattern.params('/foo').should be == {"bar" => "FOO"} }
  end

  context 'invalid syntax' do
    example 'unexpected end of capture' do
      expect { Mustermann::Flask.new('foo>bar') }.
        to raise_error(Mustermann::ParseError, 'unexpected > while parsing "foo>bar"')
    end

    example 'missing end of capture' do
      expect { Mustermann::Flask.new('foo<bar') }.
        to raise_error(Mustermann::ParseError, 'unexpected end of string while parsing "foo<bar"')
    end

    example 'unknown converter' do
      expect { Mustermann::Flask.new('foo<bar:name>') }.
        to raise_error(Mustermann::ParseError, 'unexpected converter "bar" while parsing "foo<bar:name>"')
    end

    example 'broken argument synax' do
      expect { Mustermann::Flask.new('<string(length=3=2):foo>') }.
        to raise_error(Mustermann::ParseError, 'unexpected = while parsing "<string(length=3=2):foo>"')
    end

    example 'missing )' do
      expect { Mustermann::Flask.new('<string(foo') }.
        to raise_error(Mustermann::ParseError, 'unexpected end of string while parsing "<string(foo"')
    end

    example 'missing ""' do
      expect { Mustermann::Flask.new('<string("foo') }.
        to raise_error(Mustermann::ParseError, 'unexpected end of string while parsing "<string(\\"foo"')
    end
  end
end
