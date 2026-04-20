# frozen_string_literal: true
require 'support'
require 'mustermann/set'

describe Mustermann::Set do
  # Run every example against both matching strategies to ensure they agree.
  # `use_trie: true` forces the trie; `use_trie: false` forces linear.
  shared_examples 'a set' do |use_trie:|
    subject(:set) { described_class.new(use_trie:, use_cache: false) }

    # ── basic matching ──────────────────────────────────────────────────────

    context 'basic matching' do
      before { set.add('/:name') }

      it('matches a string to a pattern') { expect(set.match('/foo')).not_to  be_nil                  }
      it('returns nil for no match')      { expect(set.match('/foo/bar')).to be_nil                   }
      it('returns a Set::Match')          { expect(set.match('/foo')).to be_a(Mustermann::Set::Match) }
      it('exposes the matched string')    { expect(set.match('/foo').to_s).to eq '/foo'               }
      it('exposes params')                { expect(set.match('/foo').params).to eq('name' => 'foo')   }
      it('supports symbol key access')    { expect(set.match('/foo')[:name]).to eq 'foo'              }
      it('supports string key access')    { expect(set.match('/foo')['name']).to eq 'foo'             }
    end

    # ── values ──────────────────────────────────────────────────────────────

    context 'values' do
      it 'returns nil value when none given' do
        set.add('/foo')
        expect(set.match('/foo').value).to be_nil
      end

      it 'stores and returns a value' do
        set.add('/foo', :handler)
        expect(set.match('/foo').value).to eq :handler
      end

      it 'stores first value on single match' do
        set.add('/foo', :a, :b)
        expect(set.match('/foo').value).to eq :a
      end

      it 'de-duplicates values for the same pattern' do
        set.add('/foo', :a)
        set.add('/foo', :a)
        expect(set.match_all('/foo').map(&:value)).to eq [:a]
      end

      it 'returns all values via match_all' do
        set.add('/foo', :a, :b)
        expect(set.match_all('/foo').map(&:value)).to eq [:a, :b]
      end

      it 'stores values per-pattern independently' do
        set.add('/foo', :foo_handler)
        set.add('/bar', :bar_handler)
        expect(set.match('/foo').value).to eq :foo_handler
        expect(set.match('/bar').value).to eq :bar_handler
      end
    end

    # ── match_all ────────────────────────────────────────────────────────────

    context 'match_all' do
      it 'returns [] when nothing matches' do
        set.add('/foo')
        expect(set.match_all('/bar')).to eq []
      end

      it 'returns all matching patterns' do
        set.add('/:a')
        set.add('/:b')
        results = set.match_all('/foo')
        expect(results.size).to eq 2
      end

      it 'preserves insertion order' do
        set.add('/:first',  :first)
        set.add('/:second', :second)
        values = set.match_all('/foo').map(&:value)
        expect(values).to eq [:first, :second]
      end
    end

    # ── peek_match ───────────────────────────────────────────────────────────

    context 'peek_match' do
      it 'matches a prefix' do
        set.add('/foo')
        m = set.peek_match('/foo/extra')
        expect(m).not_to be_nil
        expect(m.to_s).to   eq '/foo'
        expect(m.post_match).to eq '/extra'
      end

      it 'returns nil when nothing can match' do
        set.add('/foo')
        expect(set.peek_match('/bar/extra')).to be_nil
      end
    end

    # ── peek_match_all ───────────────────────────────────────────────────────

    context 'peek_match_all' do
      it 'returns all patterns that match a prefix' do
        set.add('/:a', :first)
        set.add('/:b', :second)
        results = set.peek_match_all('/foo/extra')
        expect(results.size).to eq 2
        expect(results.map(&:to_s)).to all(eq '/foo')
        expect(results.map(&:post_match)).to all(eq '/extra')
        expect(results.map(&:value)).to eq [:first, :second]
      end

      it 'returns [] when nothing matches as a prefix' do
        set.add('/foo')
        expect(set.peek_match_all('/bar/extra')).to eq []
      end
    end

    # ── [] accessor ──────────────────────────────────────────────────────────

    context '[]' do
      it 'looks up by string (matches against patterns)' do
        set.add('/foo', :result)
        expect(set['/foo']).to eq :result
      end

      it 'looks up by Pattern object' do
        pat = Mustermann.new('/foo')
        set.add(pat, :result)
        expect(set[pat]).to eq :result
      end

      it 'returns nil for no match on string lookup' do
        set.add('/foo')
        expect(set['/bar']).to be_nil
      end

      it 'raises for unsupported type' do
        expect { set[42] }.to raise_error(ArgumentError)
      end
    end

    # ── update / merge ───────────────────────────────────────────────────────

    context 'update' do
      it 'merges from a Hash' do
        set.update('/foo' => :a, '/bar' => :b)
        expect(set['/foo']).to eq :a
        expect(set['/bar']).to eq :b
      end

      it 'merges from an Array' do
        set.update(['/foo', '/bar'])
        expect(set.match('/foo')).not_to be_nil
        expect(set.match('/bar')).not_to be_nil
      end

      it 'merges from a String' do
        set.update('/foo')
        expect(set.match('/foo')).not_to be_nil
      end

      it 'merges from another Set' do
        other = described_class.new(use_trie:, use_cache: false)
        other.add('/foo', :from_other)
        set.update(other)
        expect(set['/foo']).to eq :from_other
      end

      it 'combines values when merging overlapping patterns from another Set' do
        other = described_class.new(use_trie:, use_cache: false)
        set.add('/foo',   :a)
        other.add('/foo', :b)
        set.update(other)
        expect(set.match_all('/foo').map(&:value)).to eq [:a, :b]
      end
    end

    context 'merge' do
      it 'returns a new set without modifying the original' do
        set.add('/foo', :a)
        merged = set.merge('/bar' => :b)
        expect(set.match('/bar')).to be_nil
        expect(merged['/foo']).to eq :a
        expect(merged['/bar']).to eq :b
      end
    end

    # ── patterns ─────────────────────────────────────────────────────────────

    context 'patterns' do
      it 'lists all added patterns' do
        set.add('/foo')
        set.add('/bar')
        expect(set.patterns.map(&:to_s)).to contain_exactly('/foo', '/bar')
      end
    end

    # ── except option ────────────────────────────────────────────────────────

    context 'except option' do
      it 'respects the except constraint on a pattern' do
        set.add(Mustermann.new('/:foo', except: '/bar'), :handler)
        expect(set.match('/foo').value).to eq :handler
        expect(set.match('/bar')).to be_nil
      end

      it 'falls through to an unrestricted pattern when except excludes a match' do
        set.add(Mustermann.new('/:foo', except: '/bar'), :restricted)
        set.add('/:foo', :unrestricted)
        expect(set.match('/foo').value).to eq :restricted
        expect(set.match('/bar').value).to eq :unrestricted
      end
    end

    # ── conflict resolution (ordering) ───────────────────────────────────────

    context 'conflict resolution' do
      it 'returns the first-added pattern on conflict' do
        set.add('/foo',  :static)
        set.add('/:var', :dynamic)
        expect(set.match('/foo').value).to eq :static
      end

      it 'a dynamic pattern matches what the static one does not' do
        set.add('/foo',  :static)
        set.add('/:var', :dynamic)
        expect(set.match('/bar').value).to eq :dynamic
      end

      it 'two dynamic patterns: insertion order wins' do
        set.add('/:a', :first)
        set.add('/:b', :second)
        expect(set.match('/foo').value).to eq :first
      end

      it 'match_all returns both when two patterns match' do
        set.add('/foo',  :static)
        set.add('/:var', :dynamic)
        values = set.match_all('/foo').map(&:value)
        expect(values).to contain_exactly(:static, :dynamic)
      end

      it 'match_all works with constrained captures (regex path)' do
        s = described_class.new(use_trie:, use_cache: false, capture: { id: /\d+/ })
        s.add('/:id', :handler)
        results = s.match_all('/42')
        expect(results.map(&:value)).to eq [:handler]
        expect(results.first.params['id']).to eq '42'
      end
    end

    # ── complex patterns ─────────────────────────────────────────────────────

    context 'complex patterns' do
      it 'handles nested segments' do
        set.add('/users/:id/posts/:post_id', :posts)
        m = set.match('/users/42/posts/7')
        expect(m.value).to eq :posts
        expect(m.params).to eq('id' => '42', 'post_id' => '7')
      end

      it 'handles splat captures' do
        set.add('/files/*path', :files)
        m = set.match('/files/a/b/c')
        expect(m).not_to be_nil
        # named splat (not 'splat') returns the full captured string
        expect(m.params['path']).to eq 'a/b/c'
      end

      it 'handles unnamed splat (always an array)' do
        set.add('/files/*', :files)
        m = set.match('/files/a/b/c')
        expect(m).not_to be_nil
        expect(m.params['splat']).to eq ['a/b/c']
      end

      it 'handles optional segments (rails-style)' do
        s = described_class.new(type: :rails, use_trie:, use_cache: false)
        s.add('/:controller(/:action)', :route)
        expect(s.match('/users').value).to        eq :route
        expect(s.match('/users/show').value).to   eq :route
        expect(s.match('/users').params['action']).to be_nil
        expect(s.match('/users/show').params['action']).to eq 'show'
      end

      it 'distinguishes prefix-ambiguous patterns by length' do
        set.add('/users',       :list)
        set.add('/users/:id',   :show)
        expect(set.match('/users').value).to       eq :list
        expect(set.match('/users/1').value).to     eq :show
      end

      it 'deep nesting with multiple params' do
        set.add('/:a/:b/:c', :deep)
        m = set.match('/x/y/z')
        expect(m.params).to eq('a' => 'x', 'b' => 'y', 'c' => 'z')
      end

      it 'handles URI-encoded params' do
        set.add('/:name', :cap)
        m = set.match('/hello%20world')
        expect(m.params['name']).to eq 'hello world'
      end

      it 'handles overlapping static and parameterized prefixes' do
        set.add('/users/new',  :new_form)
        set.add('/users/:id',  :show)
        expect(set.match('/users/new').value).to eq :new_form
        expect(set.match('/users/42').value).to  eq :show
      end

      it 'handles multiple splats' do
        set.add('/*/*', :two_splats)
        m = set.match('/foo/bar')
        expect(m).not_to be_nil
        expect(m.params['splat']).to eq ['foo', 'bar']
      end

      it 'handles optional prefix before required segment (sinatra-style)' do
        set.add('(/:slug)?/bar', :route)
        expect(set.match('/bar').value).to eq :route
        expect(set.match('/foo/bar').value).to eq :route
        expect(set.match('/bar').params['slug']).to be_nil
        expect(set.match('/foo/bar').params['slug']).to eq 'foo'
        expect(set.match('/baz')).to be_nil
      end

      it 'handles optional prefix before required segment (rails-style)' do
        s = described_class.new(type: :rails, use_trie:, use_cache: false)
        s.add('(/:slug)/bar', :route)
        expect(s.match('/bar').value).to eq :route
        expect(s.match('/foo/bar').value).to eq :route
        expect(s.match('/bar').params['slug']).to be_nil
        expect(s.match('/foo/bar').params['slug']).to eq 'foo'
        expect(s.match('/baz')).to be_nil
      end

      it 'resolves conflict between exact static and optional-prefix pattern' do
        set.add('/foo/bar',       :exact)
        set.add('(/:slug)?/bar',  :optional)
        expect(set.match('/foo/bar').value).to eq :exact
        expect(set.match('/baz/bar').value).to eq :optional
        expect(set.match('/bar').value).to    eq :optional
      end
    end

    # ── error handling ───────────────────────────────────────────────────────

    context 'error handling' do
      it 'rejects illegal additional_values' do
        expect { described_class.new(additional_values: :foo, use_trie:) }
          .to raise_error(ArgumentError)
      end

      it 'rejects illegal use_trie value' do
        expect { described_class.new(use_trie: :maybe) }
          .to raise_error(ArgumentError)
      end

      it 'rejects non-AST patterns' do
        expect { set.add(Mustermann.new('/foo', type: :regular)) }
          .to raise_error(ArgumentError, /Non-AST/)
      end

      it 'rejects reserved values' do
        expect { set.add('/foo', :raise) }
          .to raise_error(ArgumentError)
      end

      it 'rejects the set itself as a value' do
        expect { set.add('/foo', set) }
          .to raise_error(ArgumentError, /set itself/)
      end

      it 'rejects unsupported mapping types in update' do
        expect { set.update(42) }
          .to raise_error(ArgumentError, /unsupported mapping type/)
      end
    end

    # ── initialization shortcuts ─────────────────────────────────────────────

    context 'initialization' do
      it 'accepts patterns in the constructor' do
        s = described_class.new('/foo' => :a, '/bar' => :b, use_trie:, use_cache: false)
        expect(s['/foo']).to eq :a
        expect(s['/bar']).to eq :b
      end

      it 'accepts a zero-arity block returning a mapping' do
        s = described_class.new(use_trie:, use_cache: false) { { '/foo' => :block } }
        expect(s['/foo']).to eq :block
      end

      it 'accepts a one-argument block for imperative building' do
        s = described_class.new(use_trie:, use_cache: false) { |set| set.add('/foo', :imperative) }
        expect(s['/foo']).to eq :imperative
      end
    end

    # ── expand ───────────────────────────────────────────────────────────────

    context 'expand' do
      it 'expands using the first matching pattern' do
        set.add('/:name', :a)
        expect(set.expand(name: 'foo')).to include '/foo'
      end

      it 'expands for a specific value' do
        set.add('/users/:id', :users)
        set.add('/posts/:id', :posts)
        expect(set.expand(:users, id: '5')).to include '/users/5'
        expect(set.expand(:posts, id: '5')).to include '/posts/5'
      end

      it 'expands with additional_values behavior passed as value' do
        set.add('/:name', :handler)
        expect(set.expand(:ignore, name: 'foo')).to include '/foo'
      end

      it 'raises when conflicting behavior is specified twice' do
        set.add('/:name')
        expect { set.expand(:ignore, :raise, { name: 'foo' }) }
          .to raise_error(ArgumentError, /behavior specified multiple times/)
      end
    end
  end

  context 'with linear matching (use_trie: false)' do
    include_examples 'a set', use_trie: false
  end

  context 'with trie matching (use_trie: true)' do
    include_examples 'a set', use_trie: true
  end

  # ── strategy-specific / trie threshold ───────────────────────────────────

  context 'trie threshold' do
    it 'switches to trie when pattern count reaches threshold' do
      set = described_class.new(use_trie: 2, use_cache: false)
      set.add('/a', :a)
      set.add('/b', :b)  # triggers switch
      set.add('/c', :c)
      expect(set.match('/a').value).to eq :a
      expect(set.match('/c').value).to eq :c
    end
  end

  # ── caching ───────────────────────────────────────────────────────────────

  context 'with cache' do
    it 'returns consistent results on repeated lookups' do
      set = described_class.new(use_trie: false, use_cache: true)
      set.add('/:name', :handler)
      2.times { expect(set.match('/foo').value).to eq :handler }
    end

    it 'invalidates cache when a pattern is added' do
      set = described_class.new(use_trie: false, use_cache: true)
      set.add('/foo', :first)
      set.match('/bar')  # populate cache with nil result
      set.add('/bar', :second)
      expect(set.match('/bar').value).to eq :second
    end

    it 'supports match_all with cache enabled' do
      set = described_class.new(use_trie: false, use_cache: true)
      set.add('/:name', :handler)
      expect(set.match_all('/foo').map(&:value)).to eq [:handler]
    end

    it 'supports peek_match with cache enabled' do
      set = described_class.new(use_trie: false, use_cache: true)
      set.add('/:name', :handler)
      expect(set.peek_match('/foo/extra').value).to eq :handler
    end
  end
end
