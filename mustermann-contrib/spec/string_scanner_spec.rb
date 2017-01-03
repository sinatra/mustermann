# frozen_string_literal: true
require 'support'
require 'mustermann/string_scanner'

describe Mustermann::StringScanner do
  include Support::ScanMatcher

  subject(:scanner) { Mustermann::StringScanner.new(example_string) }
  let(:example_string) { "foo bar" }

  describe :scan do
    it { should scan("foo")     }
    it { should scan(/foo/)     }
    it { should scan(:name)     }
    it { should scan(":name")   }

    it { should_not scan(" ")   }
    it { should_not scan("bar") }

    example do
      should scan("foo")
      should scan(" ")
      should scan("bar")
    end

    example do
      scanner.position = 4
      should scan("bar")
    end

    example do
      should scan("foo")
      scanner.reset
      should scan("foo")
    end
  end

  describe :check do
    it { should check("foo")     }
    it { should check(/foo/)     }
    it { should check(:name)     }
    it { should check(":name")   }

    it { should_not check(" ")   }
    it { should_not check("bar") }

    example do
      should     check("foo")
      should_not check(" ")
      should_not check("bar")
      should     check("foo")
    end

    example do
      scanner.position = 4
      should check("bar")
    end
  end

  describe :scan_until do
    it { should scan_until("foo")     }
    it { should scan_until(":name")   }
    it { should scan_until(" ")       }
    it { should scan_until("bar")     }
    it { should_not scan_until("baz") }

    example do
      should scan_until(" ")
      should check("bar")
    end

    example do
      should scan_until(" ")
      scanner.reset
      should scan("foo")
    end
  end

  describe :check_until do
    it { should check_until("foo")     }
    it { should check_until(":name")   }
    it { should check_until(" ")       }
    it { should check_until("bar")     }
    it { should_not check_until("baz") }

    example do
      should check_until(" ")
      should_not check("bar")
    end
  end

  describe :getch do
    example { scanner.getch.should be == "f" }

    example do
      scanner.scan("foo")
      scanner.getch.should be == " "
      should scan("bar")
    end

    example do
      scanner.getch
      scanner.reset
      should scan("foo")
    end
  end

  describe :<< do
    example do
      should_not scan_until("baz")
      scanner << " baz"
      scanner.to_s.should be == "foo bar baz"
      should scan_until("baz")
    end
  end

  describe :eos? do
    it { should_not be_eos }
    example do
      scanner.position = 7
      should be_eos
    end
  end

  describe :beginning_of_line? do
    let(:example_string) { "foo\nbar" }
    it { should be_beginning_of_line }

    example do
      scanner.position = 2
      should_not be_beginning_of_line
    end

    example do
      scanner.position = 3
      should_not be_beginning_of_line
    end

    example do
      scanner.position = 4
      should be_beginning_of_line
    end
  end

  describe :rest do
    example { scanner.rest.should be == "foo bar" }
    example do
      scanner.position = 4
      scanner.rest.should be == "bar"
    end
  end

  describe :rest_size do
    example { scanner.rest_size.should be == 7 }
    example do
      scanner.position = 4
      scanner.rest_size.should be == 3
    end
  end

  describe :peek do
    example { scanner.peek(3).should be == "foo" }

    example do
      scanner.peek(3).should be == "foo"
      scanner.peek(3).should be == "foo"
    end

    example do
      scanner.position = 4
      scanner.peek(3).should be == "bar"
    end
  end

  describe :inspect do
    example { scanner.inspect.should be == '#<Mustermann::StringScanner 0/7 @ "foo bar">' }
    example do
      scanner.position = 4
      scanner.inspect.should be == '#<Mustermann::StringScanner 4/7 @ "foo bar">'
    end
  end

  describe :[] do
    example do
      should scan(:name)
      scanner['name'].should be == "foo bar"
    end

    example do
      should scan(:name, capture: /\S+/)
      scanner['name'].should be == "foo"
      should scan(" :name", capture: /\S+/)
      scanner['name'].should be == "bar"
    end

    example do
      should scan(":a",  capture: /\S+/)
      should scan(" :b", capture: /\S+/)
      scanner['a'].should be == "foo"
      scanner['b'].should be == "bar"
    end

    example do
      a = scanner.scan(":a",  capture: /\S+/)
      b = scanner.scan(" :b", capture: /\S+/)
      a.params['a'].should be == 'foo'
      b.params['b'].should be == 'bar'
      a.params['b'].should be_nil
      b.params['a'].should be_nil
    end

    example do
      result = scanner.check(":a",  capture: /\S+/)
      result.params['a'].should be == 'foo'
      scanner['a'].should be_nil
    end

    example do
      should scan(:name)
      scanner.reset
      scanner['name'].should be_nil
    end
  end

  describe :unscan do
    example do
      should scan(:name, capture: /\S+/)
      scanner['name'].should be == "foo"
      should scan(" :name", capture: /\S+/)
      scanner['name'].should be == "bar"
      scanner.unscan
      scanner['name'].should be == "foo"
      scanner.rest.should be == " bar"
    end

    example do
      should scan_until(" ")
      scanner.unscan
      scanner.rest.should be == "foo bar"
    end

    example do
      expect { scanner.unscan }.to raise_error(Mustermann::StringScanner::ScanError,
        'unscan failed: previous match record not exist')
    end
  end

  describe :terminate do
    example do
      scanner.terminate
      scanner.should be_eos
    end
  end

  describe :to_h do
    example { scanner.to_h.should be == {} }
    example do
    end
  end

  describe :to_s do
    example { scanner.to_s.should be == "foo bar" }
  end

  describe :clear_cache do
    example do
      scanner.scan("foo")
      Mustermann::StringScanner.clear_cache
      Mustermann::StringScanner.cache_size.should be == 0
    end
  end
end
