require 'support'
require 'mustermann/expander'

describe Mustermann::Expander do
  it 'expands a pattern' do
    expander = Mustermann::Expander.new("/:foo.jpg")
    expander.expand(foo: 42).should be == "/42.jpg"
  end

  it 'expands multiple patterns' do
    expander = Mustermann::Expander.new << "/:foo.:ext" << "/:foo"
    expander.expand(foo: 42, ext: 'jpg').should be == "/42.jpg"
    expander.expand(foo: 23).should be == "/23"
  end

  it 'supports setting pattern options' do
    expander = Mustermann::Expander.new(type: :rails) << "/:foo(.:ext)" << "/:bar"
    expander.expand(foo: 42, ext: 'jpg').should be == "/42.jpg"
    expander.expand(foo: 42).should be == "/42"
  end

  it 'supports combining different pattern styles' do
    expander = Mustermann::Expander.new << Mustermann.new("/:foo(.:ext)", type: :rails) << Mustermann.new("/:bar", type: :sinatra)
    expander.expand(foo: 'pony', ext: 'jpg').should be == '/pony.jpg'
    expander.expand(bar: 23).should be == "/23"
  end

  it 'ignores nil values' do
    expander = Mustermann::Expander.new << Mustermann.new("/:foo(.:ext)?")
    expander.expand(foo: 'pony', ext: nil).should be == '/pony'
  end

  describe :additional_values do
    context "illegal value" do
      example { expect { Mustermann::Expander.new(additional_values: :foo) }.to raise_error(ArgumentError) }
      example { expect { Mustermann::Expander.new('/').expand(:foo, a: 10) }.to raise_error(ArgumentError) }
    end

    context :raise do
      subject(:expander) { Mustermann::Expander.new('/:a', additional_values: :raise) }
      example { expander.expand(a: ?a).should be == '/a' }
      example { expect { expander.expand(a: ?a, b: ?b) }.to raise_error(Mustermann::ExpandError) }
      example { expect { expander.expand(b: ?b) }.to raise_error(Mustermann::ExpandError) }
    end

    context :ignore do
      subject(:expander) { Mustermann::Expander.new('/:a', additional_values: :ignore) }
      example { expander.expand(a: ?a).should be == '/a' }
      example { expander.expand(a: ?a, b: ?b).should be == '/a' }
      example { expect { expander.expand(b: ?b) }.to raise_error(Mustermann::ExpandError) }
    end

    context :append do
      subject(:expander) { Mustermann::Expander.new('/:a', additional_values: :append) }
      example { expander.expand(a: ?a).should be == '/a' }
      example { expander.expand(a: ?a, b: ?b).should be == '/a?b=b' }
      example { expect { expander.expand(b: ?b) }.to raise_error(Mustermann::ExpandError) }
    end
  end

  describe :cast do
    subject(:expander) { Mustermann::Expander.new('/:a(/:b)?') }

    example { expander.cast          { "FOOBAR"          }.expand(a: "foo")           .should be == "/FOOBAR"   }
    example { expander.cast          { |v| v.upcase      }.expand(a: "foo")           .should be == "/FOO"      }
    example { expander.cast          { |v| v.upcase      }.expand(a: "foo", b: "bar") .should be == "/FOO/BAR"  }
    example { expander.cast(:a)      { |v| v.upcase      }.expand(a: "foo", b: "bar") .should be == "/FOO/bar"  }
    example { expander.cast(:a, :b)  { |v| v.upcase      }.expand(a: "foo", b: "bar") .should be == "/FOO/BAR"  }
    example { expander.cast(Integer) { |k,v| "#{k}_#{v}" }.expand(a: "foo", b: 42)    .should be == "/foo/b_42" }

    example do
      expander.cast(:a) { |v| v.upcase   }
      expander.cast(:b) { |v| v.downcase }
      expander.expand(a: "fOo", b: "bAr").should be == "/FOO/bar"
    end
  end
end
