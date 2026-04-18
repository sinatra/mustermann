# frozen_string_literal: true
$:.unshift File.expand_path('../lib', __dir__)

require 'benchmark'
require 'mustermann'
require 'mustermann/trie'

levels      = ARGV[0].to_s.split(",").map { Integer(it) }
levels      = [1, 2, 3, 4] if levels.empty?
per_level   = ARGV[1].to_s.split(",").map { Integer(it) }
per_level   = [1, 5, 10] if per_level.empty?
runs        = Integer(ARGV[2] || 1000)
line_length = 71

generate = lambda do |levels, per_level|
  routes      = ['']
  placeholder = ':`'

  levels.times do
    routes = routes.flat_map do |prefix|
      placeholder = placeholder.succ
      segment = '`'
      per_level.times.map do
        segment = segment.succ
        "#{prefix}/#{segment}/#{placeholder}"
      end
    end
  end

  routes
end

scenarios = []

puts "", " Compilation: Array<Pattern> ".center(line_length, '=')
Benchmark.benchmark do |x|
  levels.product(per_level).each do |(l, p)|
    routes      = generate.call(l, p)
    examples    = runs.times.map { [i = rand(routes.size), routes[i].gsub(":", "")] }
    description =  "%7i routes %4i level#{l == 1 ? ' ' : 's'}" % [routes.size, l, p]
    x.report(description) { routes.map! { Mustermann.new(it) } }
    scenarios << { description:, routes:, examples: }
  end
end

puts "", " Compilation: Trie ".center(line_length, '=')
Benchmark.benchmark do |x|
  scenarios.each do |s|
    x.report(s[:description]) do
      s[:trie] = trie = Mustermann::Trie.new
      s[:routes].each_with_index { |route, index| trie.add(route, index) }
    end
  end
end

puts "", " Matching: Array<Pattern> ".center(line_length, '=')
Benchmark.bmbm do |x|
  scenarios.each do |s|
    x.report s[:description] do
      s[:examples].each do |(expected, path)|
        next if index = s[:routes].find_index { it.match(path) } and index == expected
        raise "Expected %p but got %p for %p" % [expected, index, path]
      end
    end
  end
end

puts "", " Matching: Trie ".center(line_length, '=')
Benchmark.bmbm do |x|
  scenarios.each do |s|
    x.report s[:description] do
      s[:examples].each do |(expected, path)|
        next if index = s[:trie].match(path)&.value and index == expected
        raise "Expected %p but got %p for %p" % [expected, index, path]
      end
    end
  end
end
