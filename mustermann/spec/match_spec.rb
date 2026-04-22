# frozen_string_literal: true
require 'support'
require 'mustermann/match'
require 'mustermann/sinatra'

describe Mustermann::Match do
  let(:pattern) { Mustermann::Sinatra.new('/:name') }
  subject(:match) { pattern.match('/foo') }

  # For a full match, string and to_s are both the matched string.
  its(:string)     { should be == '/foo'            }
  its(:to_s)       { should be == '/foo'            }
  its(:params)     { should be == { 'name' => 'foo' } }
  its(:post_match) { should be == ''                }
  its(:pre_match)  { should be == ''                }
  its(:to_h)       { should be == { 'name' => 'foo' } }
  its(:captures)        { should be == ['foo'] }
  its(:named_captures)  { should be == { 'name' => 'foo' } }

  # For a peek match, #string is the full searched string and #to_s is the matched portion.
  describe 'peek match' do
    subject(:peek) { pattern.peek_match('/foo/bar') }
    its(:string) { should be == '/foo/bar' }
    its(:to_s)   { should be == '/foo'     }
  end

  describe :[] do
    example('symbol key')  { match[:name].should  be == 'foo' }
    example('string key')  { match['name'].should be == 'foo' }
    example('integer key') { match[0].should      be == 'foo' }
    example('range key')   { match[0..0].should   be == ['foo'] }
    example('invalid key') do
      expect { match[1.0] }.to raise_error(ArgumentError, /key must be/)
    end
  end

  describe :values_at do
    example { match.values_at(:name, 'name').should be == ['foo', 'foo'] }
  end

  describe :deconstruct_keys do
    example { match.deconstruct_keys([:name]).should be == { name: 'foo' } }
  end

  describe :eql? do
    example { match.eql?(pattern.match('/foo')).should be true  }
    example { match.eql?(pattern.match('/bar')).should be false }
    example { match.eql?('not a match').should         be false }
  end

  describe :hash do
    example { match.hash.should be == pattern.match('/foo').hash }
    example { match.hash.should_not be == pattern.match('/bar').hash }
  end

  describe :== do
    example { (match == pattern.match('/foo')).should be true  }
    example { (match == pattern.match('/bar')).should be false }
  end

  describe 'invalid constructor arguments' do
    example('bad first argument') do
      expect { Mustermann::Match.new('not a pattern', '/foo') }.to raise_error(ArgumentError, /first argument/)
    end

    example('bad second argument') do
      expect { Mustermann::Match.new(pattern, 42) }.to raise_error(ArgumentError, /second argument/)
    end
  end
end
