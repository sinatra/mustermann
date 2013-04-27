require 'support'
require 'mustermann/ast'

describe Mustermann::AST do
  it 'raises a NotImplementedError when used directly' do
    expect { described_class.new("x") === "x" }.to raise_error(NotImplementedError)
  end
end
