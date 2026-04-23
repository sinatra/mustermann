# frozen_string_literal: true
require 'support'
require 'mustermann/pyramid'

describe Mustermann::Pyramid do
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

  pattern '/{foo}' do
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

  pattern '/*foo' do
    it { should match('/foo')     .capturing foo: 'foo' }
    it { should match('/foo/bar') .capturing foo: 'foo/bar' }

    it { should expand                  .to('/')        }
    it { should expand(foo:  nil)       .to('/')        }
    it { should expand(foo:  '')        .to('/')        }
    it { should expand(foo: 'foo')      .to('/foo')     }
    it { should expand(foo: 'foo/bar')  .to('/foo/bar') }
    it { should expand(foo: 'foo.bar')  .to('/foo.bar') }

    example { pattern.params("/foo/bar").should be == {"foo" => ["foo", "bar"]}}
    it { should generate_template('/{+foo}') }
  end

  pattern '/{foo:.*}' do
    it { should match('/')        .capturing foo: '' }
    it { should match('/foo')     .capturing foo: 'foo' }
    it { should match('/foo/bar') .capturing foo: 'foo/bar' }

    it { should expand(foo:  '')        .to('/')        }
    it { should expand(foo: 'foo')      .to('/foo')     }
    it { should expand(foo: 'foo/bar')  .to('/foo/bar') }
    it { should expand(foo: 'foo.bar')  .to('/foo.bar') }

    example { pattern.params("/foo/bar").should be == {"foo" => "foo/bar"}}
    it { should generate_template('/{foo}') }
  end
end
