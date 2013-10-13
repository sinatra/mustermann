require 'support'
require 'mustermann'
require 'mustermann/extension'
require 'sinatra/base'

describe Mustermann do
  describe :new do
    context "string argument" do
      example { Mustermann.new('')                  .should be_a(Mustermann::Sinatra)  }
      example { Mustermann.new('', type: :identity) .should be_a(Mustermann::Identity) }
      example { Mustermann.new('', type: :rails)    .should be_a(Mustermann::Rails)    }
      example { Mustermann.new('', type: :shell)    .should be_a(Mustermann::Shell)    }
      example { Mustermann.new('', type: :sinatra)  .should be_a(Mustermann::Sinatra)  }
      example { Mustermann.new('', type: :simple)   .should be_a(Mustermann::Simple)   }
      example { Mustermann.new('', type: :template) .should be_a(Mustermann::Template) }

      example { expect { Mustermann.new('', foo:  :bar) }.to raise_error(ArgumentError, "unsupported option :foo for Mustermann::Sinatra") }
      example { expect { Mustermann.new('', type: :ast) }.to raise_error(ArgumentError, "unsupported type :ast") }
    end

    context "pattern argument" do
      subject(:pattern) { Mustermann.new('') }
      example { Mustermann.new(pattern).should be == pattern }
      example { Mustermann.new(pattern, type: :rails).should be_a(Mustermann::Sinatra) }
    end

    context "regexp argument" do
      example { Mustermann.new(//)               .should be_a(Mustermann::Regular) }
      example { Mustermann.new(//, type: :rails) .should be_a(Mustermann::Regular) }
    end

    context "argument implementing #to_pattern" do
      subject(:pattern) { Class.new { def to_pattern(**o) Mustermann.new('foo', **o) end }.new }
      example { Mustermann.new(pattern)               .should be_a(Mustermann::Sinatra) }
      example { Mustermann.new(pattern, type: :rails) .should be_a(Mustermann::Rails) }
      example { Mustermann.new(pattern).to_s.should be == 'foo' }
    end
  end

  describe :[] do
    example { Mustermann[:identity] .should be == Mustermann::Identity }
    example { Mustermann[:rails]    .should be == Mustermann::Rails    }
    example { Mustermann[:shell]    .should be == Mustermann::Shell    }
    example { Mustermann[:sinatra]  .should be == Mustermann::Sinatra  }
    example { Mustermann[:simple]   .should be == Mustermann::Simple   }
    example { Mustermann[:template] .should be == Mustermann::Template }

    example { expect { Mustermann[:ast] }.to raise_error(ArgumentError, "unsupported type :ast") }
  end

  describe :extend_object do
    context 'special behavior for Sinatra only' do
      example { Object  .new.extend(Mustermann).should     be_a(Mustermann)            }
      example { Object  .new.extend(Mustermann).should_not be_a(Mustermann::Extension) }
      example { Class   .new.extend(Mustermann).should     be_a(Mustermann)            }
      example { Class   .new.extend(Mustermann).should_not be_a(Mustermann::Extension) }
      example { Sinatra .new.extend(Mustermann).should_not be_a(Mustermann)            }
      example { Sinatra .new.extend(Mustermann).should     be_a(Mustermann::Extension) }
    end
  end
end
