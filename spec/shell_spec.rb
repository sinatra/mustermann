# -*- encoding: utf-8 -*-
require 'support'
require 'mustermann/shell'

describe Mustermann::Shell do
  extend Support::Pattern

  pattern '' do
    it { should     match('')  }
    it { should_not match('/') }
  end

  pattern '/' do
    it { should     match('/')    }
    it { should_not match('/foo') }

    example { pattern.params('/').should be == {} }
    example { pattern.params('').should be_nil }
  end

  pattern '/foo' do
    it { should     match('/foo')     }
    it { should_not match('/bar')     }
    it { should_not match('/foo.bar') }
  end

  pattern '/foo/bar' do
    it { should match('/foo/bar')   }
    it { should match('/foo%2Fbar') }
    it { should match('/foo%2fbar') }
  end

  pattern '/*/bar' do
    it { should     match('/foo/bar')     }
    it { should     match('/bar/bar')     }
    it { should     match('/foo%2Fbar')   }
    it { should     match('/foo%2fbar')   }
    it { should_not match('/foo/foo/bar') }
    it { should_not match('/bar/foo')     }
  end

  pattern '/**/foo' do
    it { should match('/a/b/c/foo')   }
    it { should match('/a/b/c/foo')   }
    it { should match('/a/.b/c/foo')  }
    it { should match('/a/.b/c/foo')  }
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
    it { should     match('/path%20with%20spaces') }
    it { should_not match('/path%2Bwith%2Bspaces') }
    it { should_not match('/path+with+spaces')     }
  end

  pattern '/foo&bar' do
    it { should match('/foo&bar') }
  end

  pattern '/test.bar' do
    it { should     match('/test.bar') }
    it { should_not match('/test0bar') }
  end

  pattern '/{foo,bar}' do
    it(nil, skip: true) { should     match('/foo')    }
    it(nil, skip: true) { should     match('/bar')    }
    it { should_not match('/foobar') }
  end

  pattern '/foo/bar', uri_decode: false do
    it { should     match('/foo/bar')   }
    it { should_not match('/foo%2Fbar') }
    it { should_not match('/foo%2fbar') }
  end

  pattern "/path with spaces", uri_decode: false do
    it { should_not match('/path%20with%20spaces') }
    it { should_not match('/path%2Bwith%2Bspaces') }
    it { should_not match('/path+with+spaces')     }
  end

  describe :=~ do
    example { '/foo'.should be =~ Mustermann::Shell.new('/foo') }
  end

  context "peeking", :skip => true do
    subject(:pattern) { Mustermann::Shell.new("foo*/") }

    describe :peek_size do
      example { pattern.peek_size("foo bar/blah")   .should be == "foo bar/".size }
      example { pattern.peek_size("foo%20bar/blah") .should be == "foo%20bar/".size }
      example { pattern.peek_size("/foo bar")       .should be_nil }

      context 'with just * as pattern' do
        subject(:pattern) { Mustermann::Shell.new('*') }
        example { pattern.peek_size('foo')              .should be == 3 }
        example { pattern.peek_size('foo/bar')          .should be == 3 }
        example { pattern.peek_size('foo/bar/baz')      .should be == 3 }
        example { pattern.peek_size('foo/bar/baz/blah') .should be == 3 }
      end
    end

    describe :peek_match do
      example { pattern.peek_match("foo bar/blah")   .to_s .should be == "foo bar/" }
      example { pattern.peek_match("foo%20bar/blah") .to_s .should be == "foo%20bar/" }
      example { pattern.peek_match("/foo bar")             .should be_nil }
    end

    describe :peek_params do
      example { pattern.peek_params("foo bar/blah")   .should be == [{}, "foo bar/".size] }
      example { pattern.peek_params("foo%20bar/blah") .should be == [{}, "foo%20bar/".size] }
      example { pattern.peek_params("/foo bar")       .should be_nil }
    end
  end
end
