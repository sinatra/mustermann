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
    it { should     match('/foo')    }
    it { should     match('/bar')    }
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
end
