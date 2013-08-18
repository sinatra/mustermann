require 'mustermann/router/simple'

describe Mustermann::Router::Simple do
  describe :initialize do
    context "with implicit receiver" do
      subject(:router) { described_class.new { on('/foo') { 'bar' } } }
      example { router.call('/foo').should be == 'bar' }
    end

    context "with explicit receiver" do
      subject(:router) { described_class.new { |r| r.on('/foo') { 'bar' } } }
      example { router.call('/foo').should be == 'bar' }
    end

    context "with default" do
      subject(:router) { described_class.new(default: 'bar') }
      example { router.call('/foo').should be == 'bar' }
    end
  end

  describe :[]= do
    before { subject['/:name'] = proc { |*a| a } }
    example { subject.call('/foo').should be == ['/foo', "name" => 'foo'] }
  end

  describe :[] do
    before { subject.on('/x') { 42 } }
    example { subject['/x'].call.should be == 42 }
  end
end
