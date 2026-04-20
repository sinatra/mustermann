# frozen_string_literal: true
require 'support'
require 'mustermann/sinatra'
require 'mustermann/rails'
require 'mustermann/hybrid'

# These specs verify the regexp structure emitted by the AST compiler, with a
# focus on atomic groups `(?>...)`.  An atomic group prevents Oniguruma from
# backtracking into characters already consumed by a capture, giving a
# measurable speedup on long non-matching inputs without changing the result
# on any valid input.
#
# Safety rule: a capture is made atomic only when its *immediately following
# sibling in the AST array is a path separator whose payload is `'/'*.
# Every Mustermann capture character class (Sinatra's [^\/\?#]+, Template's
# [\w\-\.~%]+, etc.) excludes '/', so the greedy match naturally stops before
# '/' — committing atomically never affects correctness.
#
# More permissive conditions are intentionally avoided:
# - End-of-array is NOT used because template expressions nest captures inside
#   inner arrays where "end of array" does not mean "end of pattern" (e.g.
#   {name}bar would atomicize :name and prevent backtracking to the literal).
# - Non-'/' separators (e.g. '.' in {.a,b,c}) are NOT used because the
#   character class [\w\-\.~%] includes '.'.
#
# Exception: with_look_ahead head captures are made atomic (when greedy)
# because the look-ahead constraint already limits what the capture can match.
#
# Note on regex escaping: to match the literal string `(?>` inside a Ruby
# regexp, all three characters must be escaped: `/\(\?>/` — `\(` is literal
# `(`, `\?` is literal `?`, `>` is literal `>`.  Similarly `(?<name>(?>` is
# matched by `/\(\?<name>\(\?>/`.  Using `/\(\?<name>\(?>/` is WRONG because
# `\(?` means "optionally match a literal `(`" (the `?` is a quantifier).

describe 'Atomic group compilation' do
  # Helper: returns the raw Regexp source for a pattern string.
  def src(pattern_string, type: :sinatra, **opts)
    Mustermann.new(pattern_string, type: type, **opts).to_regexp.source
  end

  # ── Single captures ─────────────────────────────────────────────────────────

  context 'single named segment at end of pattern (/:name)' do
    # No '/' follows :name — the rule requires a '/' separator next sibling.
    it 'does not get an atomic group (no "/" follows)' do
      expect(src('/:name')).not_to include('(?>')
    end
  end

  context 'single named segment before a "/" separator (/:name/suffix)' do
    it 'gets an atomic group because "/" follows immediately' do
      expect(src('/:name/suffix')).to include('(?>')
    end

    it 'the named capture surrounds the atomic group' do
      expect(src('/:name/suffix')).to match(/\(\?<name>\(\?>/)
    end
  end

  context 'two named segments separated by / (/:a/:b)' do
    # :a is followed by '/' → atomic.  :b is at end → NOT atomic.
    it 'wraps the first capture atomically (before "/")' do
      expect(src('/:a/:b')).to match(/\(\?<a>\(\?>/)
    end

    it 'does not wrap the last capture (nothing follows)' do
      expect(src('/:a/:b')).not_to match(/\(\?<b>\(\?>/)
    end
  end

  context 'three named segments separated by / (/:a/:b/:c)' do
    # :a and :b before '/' → atomic.  :c at end → NOT atomic.
    it 'atomicizes :a (before "/")' do
      expect(src('/:a/:b/:c')).to match(/\(\?<a>\(\?>/)
    end

    it 'atomicizes :b (before "/")' do
      expect(src('/:a/:b/:c')).to match(/\(\?<b>\(\?>/)
    end

    it 'does not atomicize :c (at end)' do
      expect(src('/:a/:b/:c')).not_to match(/\(\?<c>\(\?>/)
    end
  end

  context 'four named segments separated by / (/:a/:b/:c/:d)' do
    it 'atomicizes :a, :b, :c (each before "/"), not :d (at end)' do
      r = src('/:a/:b/:c/:d')
      expect(r).to     match(/\(\?<a>\(\?>/)
      expect(r).to     match(/\(\?<b>\(\?>/)
      expect(r).to     match(/\(\?<c>\(\?>/)
      expect(r).not_to match(/\(\?<d>\(\?>/)
    end
  end

  # ── Splats ──────────────────────────────────────────────────────────────────

  context 'splat (*) captures' do
    it 'does not wrap a named splat in an atomic group' do
      expect(src('/*path')).not_to include('(?>')
    end

    it 'does not wrap an unnamed splat in an atomic group' do
      expect(src('/*')).not_to include('(?>')
    end

    it 'does not make a splat atomic even when a "/" follows' do
      # splats are excluded explicitly — non-greedy .*? must not be atomic
      r = src('/*path/:name')
      expect(r).not_to match(/\(\?<path>\(\?>/)
    end

    it 'does not make the named segment after a splat atomic (no "/" after :name)' do
      # :name is at end-of-pattern, so no '/' follows → not atomic
      expect(src('/*path/:name')).not_to match(/\(\?<name>\(\?>/)
    end

    it 'does not produce any atomic groups when all captures are splats' do
      expect(src('/*a/*b').scan('(?>').size).to eq 0
    end
  end

  # ── Captures next to literal characters ────────────────────────────────────

  context 'capture followed by a literal dot (/:a.:b)' do
    it 'does not atomicize :a (dot, not "/", follows)' do
      expect(src('/:a.:b')).not_to match(/\(\?<a>\(\?>/)
    end

    it 'does not atomicize :b (at end, no "/" follows)' do
      expect(src('/:a.:b')).not_to match(/\(\?<b>\(\?>/)
    end

    it 'produces no atomic groups at all' do
      expect(src('/:a.:b').scan('(?>').size).to eq 0
    end
  end

  context 'capture followed by a literal hyphen (/:a-:b)' do
    it 'does not atomicize :a (hyphen, not "/", follows)' do
      expect(src('/:a-:b')).not_to match(/\(\?<a>\(\?>/)
    end

    it 'does not atomicize :b (at end, no "/" follows)' do
      expect(src('/:a-:b')).not_to match(/\(\?<b>\(\?>/)
    end
  end

  context 'capture followed by a literal at-sign (/:user@:host)' do
    it 'does not atomicize :user (at-sign, not "/", follows)' do
      expect(src('/:user@:host')).not_to match(/\(\?<user>\(\?>/)
    end

    it 'does not atomicize :host (at end)' do
      expect(src('/:user@:host')).not_to match(/\(\?<host>\(\?>/)
    end
  end

  # ── Optional segments ───────────────────────────────────────────────────────

  context 'capture followed by optional group (/:a(/:b)?)' do
    # :a is followed by the optional node itself (not a bare separator).
    it 'does not atomicize :a (next sibling is an optional, not "/")' do
      expect(src('/:a(/:b)?')).not_to match(/\(\?<a>\(\?>/)
    end

    # :b is inside the optional array at end-of-inner-array — but the rule
    # requires a "/" sibling, not just end-of-array.
    it 'does not atomicize :b inside the optional (no "/" sibling)' do
      expect(src('/:a(/:b)?')).not_to match(/\(\?<b>\(\?>/)
    end

    it 'produces no atomic groups at all' do
      expect(src('/:a(/:b)?').scan('(?>').size).to eq 0
    end
  end

  context 'capture followed by optional capture without separator (/:a:b?)' do
    # The ArrayTransform inserts a with_look_ahead node; the translator forces
    # atomic:true on the head (when greedy) regardless of siblings.
    it 'uses look-ahead for :a (no separator between captures)' do
      expect(src('/:a:b?')).to include('?!')
    end

    it 'atomicizes the look-ahead head capture (:a)' do
      expect(src('/:a:b?')).to match(/\(\?<a>\(\?>/)
    end
  end

  # ── Correctness: atomic groups must not change match results ────────────────

  context 'correctness: /:name' do
    subject(:pattern) { Mustermann.new('/:name') }

    it 'matches /alice'            do expect(pattern).to match('/alice')            end
    it 'matches /alice-smith'      do expect(pattern).to match('/alice-smith')      end
    it 'matches /file.tar.gz'      do expect(pattern).to match('/file.tar.gz')      end
    it 'matches /hello_world'      do expect(pattern).to match('/hello_world')      end
    it 'matches /42'               do expect(pattern).to match('/42')               end
    it 'does not match /'          do expect(pattern).not_to match('/')             end
    it 'does not match /a/b'       do expect(pattern).not_to match('/a/b')          end
    it 'does not match /a?b=c'     do expect(pattern).not_to match('/a?b=c')        end

    it 'captures the segment correctly' do
      expect(pattern.match('/hello')[:name]).to eq 'hello'
    end
  end

  context 'correctness: /:a/:b' do
    subject(:pattern) { Mustermann.new('/:a/:b') }

    it 'matches /foo/bar'                do expect(pattern).to match('/foo/bar')         end
    it 'matches /users/42'               do expect(pattern).to match('/users/42')        end
    it 'does not match /foo'             do expect(pattern).not_to match('/foo')         end
    it 'does not match /foo/bar/baz'     do expect(pattern).not_to match('/foo/bar/baz') end

    it 'captures both segments' do
      m = pattern.match('/hello/world')
      expect(m[:a]).to eq 'hello'
      expect(m[:b]).to eq 'world'
    end

    it 'handles percent-encoded characters in the input' do
      m = pattern.match('/hello%20world/foo')
      expect(m[:a]).to eq 'hello world'
    end
  end

  context 'correctness: /:a/:b/:c' do
    subject(:pattern) { Mustermann.new('/:a/:b/:c') }

    it 'matches /x/y/z' do expect(pattern).to match('/x/y/z') end
    it 'does not match /x/y' do expect(pattern).not_to match('/x/y') end

    it 'captures all three' do
      m = pattern.match('/one/two/three')
      expect(m[:a]).to eq 'one'
      expect(m[:b]).to eq 'two'
      expect(m[:c]).to eq 'three'
    end
  end

  context 'correctness: /:a/:b/:c/:d' do
    subject(:pattern) { Mustermann.new('/:a/:b/:c/:d') }

    it 'captures all four segments' do
      m = pattern.match('/w/x/y/z')
      expect(m[:a]).to eq 'w'
      expect(m[:b]).to eq 'x'
      expect(m[:c]).to eq 'y'
      expect(m[:d]).to eq 'z'
    end
  end

  context 'correctness: /:a.:b (dot separator)' do
    subject(:pattern) { Mustermann.new('/:a.:b') }

    it 'matches /foo.bar'         do expect(pattern).to match('/foo.bar')         end
    it 'matches /index.html'      do expect(pattern).to match('/index.html')      end
    it 'does not match /foobar'   do expect(pattern).not_to match('/foobar')      end
    it 'does not match /foo/bar'  do expect(pattern).not_to match('/foo/bar')     end

    it 'splits correctly on the dot' do
      m = pattern.match('/file.json')
      expect(m[:a]).to eq 'file'
      expect(m[:b]).to eq 'json'
    end

    it 'handles greedy ambiguity: last dot wins' do
      m = pattern.match('/a.b.c')
      expect(m[:b]).to eq 'c'
    end
  end

  context 'correctness: /:a-:b (hyphen separator)' do
    subject(:pattern) { Mustermann.new('/:a-:b') }

    it 'matches /foo-bar'    do expect(pattern).to match('/foo-bar')    end
    it 'matches /2024-01'    do expect(pattern).to match('/2024-01')    end
    it 'does not match /foo' do expect(pattern).not_to match('/foo')    end

    it 'splits correctly' do
      m = pattern.match('/first-last')
      expect(m[:a]).to eq 'first'
      expect(m[:b]).to eq 'last'
    end
  end

  context 'correctness: /*path/:name' do
    subject(:pattern) { Mustermann.new('/*path/:name') }

    it 'matches /a/b'      do expect(pattern).to match('/a/b')      end
    it 'matches /a/b/c'    do expect(pattern).to match('/a/b/c')    end
    it 'matches /dir/file' do expect(pattern).to match('/dir/file') end
    it 'does not match /'  do expect(pattern).not_to match('/')     end

    it 'captures the last segment as :name' do
      m = pattern.match('/a/b/last')
      expect(m[:name]).to eq 'last'
      expect(m[:path]).to eq 'a/b'
    end

    it 'captures single-segment paths' do
      m = pattern.match('/dir/file.txt')
      expect(m[:name]).to eq 'file.txt'
      expect(m[:path]).to eq 'dir'
    end
  end

  context 'correctness: /:a:b? (adjacent optional)' do
    subject(:pattern) { Mustermann.new('/:a:b?') }

    it 'matches /hello'      do expect(pattern).to match('/hello')      end
    it 'matches /helloworld' do expect(pattern).to match('/helloworld') end
    it 'does not match /'    do expect(pattern).not_to match('/')       end

    it 'gives :a a non-empty value' do
      m = pattern.match('/hello')
      expect(m[:a]).to_not be_empty
    end
  end

  context 'correctness: /:a(/:b)? (optional path segment)' do
    subject(:pattern) { Mustermann.new('/:a(/:b)?') }

    it 'matches /foo'          do expect(pattern).to match('/foo')     end
    it 'matches /foo/bar'      do expect(pattern).to match('/foo/bar') end
    it 'does not match /foo/'  do expect(pattern).not_to match('/foo/') end

    it 'captures only :a when :b absent' do
      m = pattern.match('/only')
      expect(m[:a]).to eq 'only'
      expect(m[:b]).to be_nil
    end

    it 'captures both when :b present' do
      m = pattern.match('/users/42')
      expect(m[:a]).to eq 'users'
      expect(m[:b]).to eq '42'
    end
  end

  context 'correctness: /users/:id.:format' do
    subject(:pattern) { Mustermann.new('/users/:id.:format') }

    it 'matches /users/42.json'   do expect(pattern).to match('/users/42.json')   end
    it 'matches /users/alice.xml' do expect(pattern).to match('/users/alice.xml') end

    it 'captures id and format' do
      m = pattern.match('/users/99.xml')
      expect(m[:id]).to eq '99'
      expect(m[:format]).to eq 'xml'
    end
  end

  context 'correctness: constant-only patterns' do
    it 'matches /foo/bar exactly'        do expect(Mustermann.new('/foo/bar')).to match('/foo/bar')     end
    it 'does not match /foo/baz'         do expect(Mustermann.new('/foo/bar')).not_to match('/foo/baz') end
    it 'matches /'                       do expect(Mustermann.new('/')).to match('/')                  end
    it 'does not match /x for pattern /' do expect(Mustermann.new('/')).not_to match('/x')             end
  end

  # ── Atomic group counts ─────────────────────────────────────────────────────
  # Only captures BEFORE a "/" separator get atomic groups.

  context 'regexp structure: /:name (single segment at end)' do
    it 'has no atomic groups (no "/" follows)' do
      expect(src('/:name').scan('(?>').size).to eq 0
    end
  end

  context 'regexp structure: /:a/:b' do
    it 'has exactly one atomic group (only :a, before "/")' do
      expect(src('/:a/:b').scan('(?>').size).to eq 1
    end
  end

  context 'regexp structure: /:a/:b/:c' do
    it 'has exactly two atomic groups (:a and :b, each before "/")' do
      expect(src('/:a/:b/:c').scan('(?>').size).to eq 2
    end
  end

  context 'regexp structure: /*path/:name' do
    it 'has no atomic groups (splat excluded, :name at end)' do
      expect(src('/*path/:name').scan('(?>').size).to eq 0
    end
  end

  context 'regexp structure: /*a/*b' do
    it 'has no atomic groups (both are splats)' do
      expect(src('/*a/*b').scan('(?>').size).to eq 0
    end
  end

  context 'regexp structure: /foo/bar (no captures)' do
    it 'has no atomic groups' do
      expect(src('/foo/bar').scan('(?>').size).to eq 0
    end
  end

  context 'regexp structure: /:a/:b/:c/:d' do
    it 'has exactly three atomic groups (:a, :b, :c — each before "/")' do
      expect(src('/:a/:b/:c/:d').scan('(?>').size).to eq 3
    end
  end

  # ── Rails pattern type ──────────────────────────────────────────────────────

  context 'Rails patterns' do
    it 'does not atomicize end-of-pattern capture in /:name' do
      expect(src('/:name', type: :rails)).not_to include('(?>')
    end

    it 'has one atomic group in /:a/:b (only :a, before "/")' do
      r = src('/:a/:b', type: :rails)
      expect(r.scan('(?>').size).to eq 1
    end

    it 'atomicizes :id (look-ahead head) in /:id(.:format)' do
      r = src('/:id(.:format)', type: :rails)
      expect(r).to match(/\(\?<id>\(\?>/)
    end

    it 'does not atomicize :format (at end of optional, no "/" follows)' do
      r = src('/:id(.:format)', type: :rails)
      expect(r).not_to match(/\(\?<format>\(\?>/)
    end

    it 'correctly matches /:id(.:format) with format' do
      p = Mustermann.new('/:id(.:format)', type: :rails)
      m = p.match('/42.json')
      expect(m[:id]).to eq '42'
      expect(m[:format]).to eq 'json'
    end

    it 'correctly matches /:id(.:format) without format' do
      p = Mustermann.new('/:id(.:format)', type: :rails)
      m = p.match('/42')
      expect(m[:id]).to eq '42'
      expect(m[:format]).to be_nil
    end

    it 'correctly matches /:a/:b' do
      p = Mustermann.new('/:a/:b', type: :rails)
      m = p.match('/foo/bar')
      expect(m[:a]).to eq 'foo'
      expect(m[:b]).to eq 'bar'
    end

    it 'works with greedy: false' do
      p = Mustermann.new('/:file(.:ext)', type: :rails, greedy: false)
      expect(p).to match('/pony')
      expect(p).to match('/pony.jpg')
      expect(p).to match('/pony.png.jpg')
    end
  end

  # ── Hybrid pattern type ─────────────────────────────────────────────────────

  context 'Hybrid patterns' do
    it 'has one atomic group in /:a/:b (only :a, before "/")' do
      r = src('/:a/:b', type: :hybrid)
      expect(r.scan('(?>').size).to eq 1
    end

    it 'does not atomicize the splat in /*path/:name' do
      r = src('/*path/:name', type: :hybrid)
      expect(r).not_to match(/\(\?<path>\(\?>/)
    end

    it 'does not atomicize :name in /*path/:name (at end, no "/" follows)' do
      r = src('/*path/:name', type: :hybrid)
      expect(r).not_to match(/\(\?<name>\(\?>/)
    end

    it 'correctly matches /*path/:name' do
      p = Mustermann.new('/*path/:name', type: :hybrid)
      m = p.match('/a/b/file')
      expect(m[:path]).to eq 'a/b'
      expect(m[:name]).to eq 'file'
    end
  end

  # ── URI-encoding: literal dots and encoded variants ─────────────────────────

  context '/:a.:b (URI-decoded literal dot)' do
    it 'produces no atomic groups (dot is not "/" for either position)' do
      r = src('/:a.:b')
      expect(r.scan('(?>').size).to eq 0
    end
  end
end
