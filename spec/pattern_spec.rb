require 'support'
require 'mustermann/pattern'

describe Mustermann::Pattern do
  it 'raises a NotImplementedError when used directly' do
    expect { described_class.new("") === "" }.to raise_error(NotImplementedError)
  end

  it 'raises an ArgumentError for unknown options' do
    expect { described_class.new("", foo: :bar) }.to raise_error(ArgumentError)
  end

  it 'does not complain about unknown options if ignore_unknown_options is enabled' do
    expect { described_class.new("", foo: :bar, ignore_unknown_options: true) }.not_to raise_error
  end
end
