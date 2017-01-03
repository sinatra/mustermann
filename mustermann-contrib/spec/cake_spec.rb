# frozen_string_literal: true
require 'support'
require 'mustermann/cake'

describe Mustermann::Cake do
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

  pattern '/*' do
    it { should match('/')        }
    it { should match('/foo')     }
    it { should match('/foo/bar') }

    example { pattern.params('/foo/bar') .should be == {"splat" => ["foo", "bar"]}}
    it { should generate_template('/{+splat}') }
  end

  pattern '/**' do
    it { should match('/')        .capturing splat: ''        }
    it { should match('/foo')     .capturing splat: 'foo'     }
    it { should match('/foo/bar') .capturing splat: 'foo/bar' }

    example { pattern.params('/foo/bar') .should be == {"splat" => ["foo/bar"]} }
    it { should generate_template('/{+splat}') }
  end
end
