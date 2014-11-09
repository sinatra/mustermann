require 'mustermann/router/simple'

describe Mustermann::Router::Simple do
  describe :initialize do
    context "with implicit receiver" do
      subject(:router) { Mustermann::Router::Simple.new { on('/foo') { 'bar' } } }
      example { router.call('/foo').should be == 'bar' }
    end

    context "with explicit receiver" do
      subject(:router) { Mustermann::Router::Simple.new { |r| r.on('/foo') { 'bar' } } }
      example { router.call('/foo').should be == 'bar' }
    end

    context "with default" do
      subject(:router) { Mustermann::Router::Simple.new(default: 'bar') }
      example { router.call('/foo').should be == 'bar' }
    end
  end

  describe :[]= do
    subject(:router) { Mustermann::Router::Simple.new }
    before { router['/:name'] = proc { |*a| a } }
    example { router.call('/foo').should be == ['/foo', "name" => 'foo'] }
  end

  describe :[] do
    subject(:router) { Mustermann::Router::Simple.new }
    before { router.on('/x') { 42 } }
    example { router['/x'].call.should be == 42 }
  end
end
