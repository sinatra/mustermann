require 'mustermann/router/rack'

describe Mustermann::Router::Rack do
  include Rack::Test::Methods
  subject(:app) { Mustermann::Router::Rack.new }

  context 'matching' do
    before { app.on('/foo') { [418, {'Content-Type' => 'text/plain'}, 'bar'] } }
    example { get('/foo').status.should be == 418 }
    example { get('/bar').status.should be == 404 }
  end

  context "params" do
    before { app.on('/:name') { |e| [200, {'Content-Type' => 'text/plain'}, e['mustermann.params']['name']] } }
    example { get('/foo').body.should be == 'foo' }
    example { get('/bar').body.should be == 'bar' }
  end

  context 'X-Cascade: pass' do
    before do
      app.on('/') { [200, { 'X-Cascade'    => 'pass'       }, ['a']] }
      app.on('/') { [200, { 'x-cascade'    => 'pass'       }, ['b']] }
      app.on('/') { [200, { 'Content-Type' => 'text/plain' }, ['c']] }
      app.on('/') { [200, { 'Content-Type' => 'text/plain' }, ['d']] }
    end

    example { get('/').body.should be == 'c' }
  end

  context 'throw :pass' do
    before do
      app.on('/') { throw :pass }
      app.on('/') { [200, { 'Content-Type' => 'text/plain' }, ['b']] }
      app.on('/') { [200, { 'Content-Type' => 'text/plain' }, ['c']] }
    end

    example { get('/').body.should be == 'b' }
  end
end
