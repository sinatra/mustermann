# frozen_string_literal: true
require 'support'
require 'mustermann/router'

describe Mustermann::Router do
  def env(method: 'GET', path: '/')
    { 'REQUEST_METHOD' => method, 'PATH_INFO' => path }
  end

  # ── NOT_FOUND constant ─────────────────────────────────────────────────────

  describe 'NOT_FOUND' do
    it 'is a 404 with X-Cascade: pass' do
      router = described_class.new
      status, headers, = router.call(env(path: '/missing'))
      expect(status).to eq 404
      expect(headers['X-Cascade']).to eq 'pass'
    end

    it 'is frozen' do
      not_found = Mustermann::Router.send(:const_get, :NOT_FOUND)
      expect(not_found).to be_frozen
    end
  end

  # ── basic routing ──────────────────────────────────────────────────────────

  context 'basic routing' do
    subject(:router) do
      described_class.new do
        get('/hello') { |_env| [200, {}, ['hello']] }
      end
    end

    it 'routes a matching GET request' do
      status, = router.call(env(path: '/hello'))
      expect(status).to eq 200
    end

    it 'returns 404 for a non-matching path' do
      status, = router.call(env(path: '/goodbye'))
      expect(status).to eq 404
    end

    it 'returns 404 for the wrong HTTP method' do
      status, = router.call(env(method: 'POST', path: '/hello'))
      expect(status).to eq 404
    end
  end

  # ── match stored in env ────────────────────────────────────────────────────

  context 'match stored in env' do
    it 'stores the match in env["mustermann.match"] by default' do
      router = described_class.new do
        get('/:name') { |e| [200, {}, [e['mustermann.match'][:name]]] }
      end
      _, _, body = router.call(env(path: '/alice'))
      expect(body).to eq ['alice']
    end

    it 'exposes params from the match' do
      captured = nil
      router = described_class.new do
        get('/:id') { |e| captured = e['mustermann.match'].params; [200, {}, []] }
      end
      router.call(env(path: '/42'))
      expect(captured).to eq('id' => '42')
    end

    it 'uses a custom key when specified' do
      router = described_class.new(key: 'my.match') do
        get('/:x') { |e| [200, {}, [e['my.match'][:x]]] }
      end
      _, _, body = router.call(env(path: '/world'))
      expect(body).to eq ['world']
    end

    it 'does not mutate the original env hash' do
      router = described_class.new do
        get('/foo') { |_e| [200, {}, []] }
      end
      original = env(path: '/foo')
      router.call(original)
      expect(original).not_to have_key('mustermann.match')
    end
  end

  # ── fallback ───────────────────────────────────────────────────────────────

  context 'fallback' do
    it 'uses the default NOT_FOUND when no fallback is given' do
      router = described_class.new
      status, headers, = router.call(env)
      expect(status).to eq 404
      expect(headers['X-Cascade']).to eq 'pass'
    end

    it 'returns a mutable response from the default fallback so middleware can modify it' do
      router = described_class.new
      response = router.call(env(path: '/missing'))
      expect(response).not_to be_frozen
    end

    it 'accepts a callable as the first positional argument' do
      custom = ->(_env) { [503, {}, ['down']] }
      router = described_class.new(custom)
      status, _, body = router.call(env)
      expect(status).to eq 503
      expect(body).to eq ['down']
    end

    it 'accepts a callable via #fallback' do
      router = described_class.new
      router.fallback ->(_env) { [410, {}, ['gone']] }
      status, = router.call(env)
      expect(status).to eq 410
    end

    it 'accepts a block via #fallback' do
      router = described_class.new
      router.fallback { |_env| [418, {}, ["I'm a teapot"]] }
      status, = router.call(env)
      expect(status).to eq 418
    end
  end

  # ── HTTP verb shorthand methods ────────────────────────────────────────────

  context 'HTTP verb shorthand methods' do
    %w[GET HEAD POST PUT PATCH DELETE OPTIONS LINK UNLINK].each do |verb|
      it "defines ##{verb.downcase} routing" do
        router = described_class.new
        router.send(verb.downcase, '/test') { |_env| [200, {}, [verb]] }
        status, _, body = router.call(env(method: verb, path: '/test'))
        expect(status).to eq 200
        expect(body).to eq [verb]
      end
    end
  end

  # ── #route method ──────────────────────────────────────────────────────────

  context '#route' do
    it 'adds a route with a block' do
      router = described_class.new
      router.route('GET', '/ping') { |_env| [200, {}, ['pong']] }
      _, _, body = router.call(env(path: '/ping'))
      expect(body).to eq ['pong']
    end

    it 'adds a route with a callable target' do
      app = ->(_env) { [200, {}, ['app']] }
      router = described_class.new
      router.route('POST', '/submit', app)
      _, _, body = router.call(env(method: 'POST', path: '/submit'))
      expect(body).to eq ['app']
    end

    it 'raises ArgumentError for an unknown verb' do
      router = described_class.new
      expect { router.route('BREW', '/coffee') { } }.to raise_error(ArgumentError, /unknown verb/)
    end

    it 'raises ArgumentError when neither target nor block is given' do
      router = described_class.new
      expect { router.route('GET', '/foo') }.to raise_error(ArgumentError, /target/)
    end
  end

  # ── DSL block at construction ──────────────────────────────────────────────

  context 'DSL block at construction' do
    it 'evaluates the block in router context' do
      router = described_class.new do
        get('/a') { |_| [200, {}, ['a']] }
        post('/b') { |_| [201, {}, ['b']] }
      end
      expect(router.call(env(path: '/a')).first).to eq 200
      expect(router.call(env(method: 'POST', path: '/b')).first).to eq 201
    end
  end

  # ── pattern options ────────────────────────────────────────────────────────

  context 'pattern options' do
    it 'forwards options to Mustermann (e.g. type: :rails)' do
      router = described_class.new(type: :rails) do
        get('/:id(.:format)') { |e| [200, {}, [e['mustermann.match'][:id]]] }
      end
      status, _, body = router.call(env(path: '/42.json'))
      expect(status).to eq 200
      expect(body).to eq ['42']
    end
  end

  # ── #path_for URL generation ───────────────────────────────────────────────

  context '#path_for' do
    it 'generates a path for a registered handler' do
      target = ->(_env) { [200, {}, []] }
      router = described_class.new do
        get '/users/:id', target
      end
      expect(router.path_for(target, id: '5')).to eq '/users/5'
    end

    it 'generates a path searching across all verbs' do
      target = ->(_env) { [200, {}, []] }
      router = described_class.new do
        delete '/posts/:slug', target
      end
      expect(router.path_for(target, slug: 'hello')).to eq '/posts/hello'
    end
  end

  # ── middleware usage ───────────────────────────────────────────────────────

  context 'middleware usage' do
    it 'passes unmatched requests to the inner app (first positional arg)' do
      inner = ->(_env) { [200, {}, ['inner']] }
      router = described_class.new(inner) do
        get('/handled') { |_| [200, {}, ['handled']] }
      end
      _, _, body = router.call(env(path: '/unhandled'))
      expect(body).to eq ['inner']
    end

    it 'does not call the inner app for matched routes' do
      inner = ->(_env) { raise 'should not be called' }
      router = described_class.new(inner) do
        get('/handled') { |_| [200, {}, ['handled']] }
      end
      expect { router.call(env(path: '/handled')) }.not_to raise_error
    end
  end
end
