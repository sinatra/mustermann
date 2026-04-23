# frozen_string_literal: true
require 'support'
require 'mustermann/hybrid'

describe Mustermann::Hybrid do
  extend Support::Pattern

  pattern '' do
    it { should     match('') }
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

  pattern '/:name' do
    it { should match('/alice')   .capturing name: 'alice'   }
    it { should match('/foo.bar') .capturing name: 'foo.bar' }

    it { should_not match('/foo/bar') }
    it { should_not match('/')        }

    it { should generate_template('/{name}') }
  end

  pattern '/:foo/:bar' do
    it { should match('/hello/world') .capturing foo: 'hello', bar: 'world' }

    it { should generate_template('/{foo}/{bar}') }
  end

  pattern '/*' do
    it { should match('/')        .capturing splat: ''        }
    it { should match('/foo')     .capturing splat: 'foo'     }
    it { should match('/foo/bar') .capturing splat: 'foo/bar' }

    it { should generate_template('/{+splat}') }
  end

  pattern '/*foo' do
    it { should match('/')        .capturing foo: ''        }
    it { should match('/foo')     .capturing foo: 'foo'     }
    it { should match('/foo/bar') .capturing foo: 'foo/bar' }

    it { should generate_template('/{+foo}') }
  end

  pattern '/{name}' do
    it { should match('/alice') .capturing name: 'alice' }
    it { should generate_template('/{name}') }
  end

  pattern '/{+path}' do
    it { should match('/a/b/c') .capturing path: 'a/b/c' }
    it { should generate_template('/{+path}') }
  end

  # Groups without | are implicitly optional (Rails behavior)
  pattern '/fo(o)' do
    it { should     match('/foo') }
    it { should     match('/fo')  }
    it { should_not match('/')    }
    it { should_not match('/f')   }

    it { should generate_template('/foo') }
    it { should generate_template('/fo')  }
  end

  pattern '/scope(/nested)' do
    it { should     match('/scope/nested') }
    it { should     match('/scope')        }
    it { should_not match('/scope/')       }
  end

  pattern '/:file(.:ext)' do
    it { should match('/pony')     .capturing file: 'pony', ext: nil   }
    it { should match('/pony.jpg') .capturing file: 'pony', ext: 'jpg' }

    it { should generate_template('/{file}')       }
    it { should generate_template('/{file}.{ext}') }
  end

  pattern '/:user(@:host)' do
    it { should match('/alice')     .capturing user: 'alice', host: nil   }
    it { should match('/alice@foo') .capturing user: 'alice', host: 'foo' }
  end

  pattern '/:controller(/:action(/:id))' do
    it { should match('/posts')        .capturing controller: 'posts', action: nil,    id: nil  }
    it { should match('/posts/show')   .capturing controller: 'posts', action: 'show', id: nil  }
    it { should match('/posts/show/1') .capturing controller: 'posts', action: 'show', id: '1'  }
  end

  # Groups with | are NOT implicitly optional
  pattern '/(foo|bar)' do
    it { should     match('/foo') }
    it { should     match('/bar') }
    it { should_not match('/')    }

    it { should generate_template('/foo') }
    it { should generate_template('/bar') }
  end

  pattern '/scope/(a|b)' do
    it { should     match('/scope/a') }
    it { should     match('/scope/b') }
    it { should_not match('/scope/')  }
    it { should_not match('/scope')   }
  end

  pattern '/(:a/:b|:c)' do
    it { should     match('/foo')     .capturing c: 'foo'           }
    it { should     match('/foo/bar') .capturing a: 'foo', b: 'bar' }
    it { should_not match('/')                                       }
  end

  # Explicit ? makes groups with | optional
  pattern '/(foo|bar)?' do
    it { should match('/foo') }
    it { should match('/bar') }
    it { should match('/')    }
  end

  pattern '/scope/(a|b)?' do
    it { should     match('/scope/a') }
    it { should     match('/scope/b') }
    it { should     match('/scope/')  }
    it { should_not match('/scope')   }
  end
end
