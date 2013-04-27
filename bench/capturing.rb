$:.unshift File.expand_path('../lib', __dir__)

require 'benchmark'
require 'mustermann'
require 'addressable/template'

list = [
  /\A\/(?<splat>.*?)\/(?<name>[^\/\?#]+)\Z/,
  Mustermann.new('/*/:name',          type: :sinatra),
  Mustermann.new('/*/:name',          type: :simple),
  Mustermann.new('/*prefix/:name',    type: :rails),
  Mustermann.new('{/prefix*}/{name}', type: :template),
  #Addressable::Template.new('{/prefix*}/{name}')
]

string = '/a/b/c/d'

Benchmark.bmbm do |x|
  list.each do |pattern|
    x.report pattern.class.to_s do
      100_000.times { pattern.match(string).captures }
    end
  end
end