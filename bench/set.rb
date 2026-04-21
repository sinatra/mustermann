# frozen_string_literal: true
$:.unshift File.expand_path('../mustermann/lib', __dir__)

require 'mustermann'
require 'mustermann/set'
require 'benchmark'

options     = { type: :sinatra }
nesting     = nil
route_count = [10, 20, 50, 100, 200, 500, 1000, 10000]
match_count = 1000

while ARGV.any?
  case ARGV.shift
  when "--trie"           then options[:use_trie] = ARGV.empty? || ARGV.first.start_with?("-") ? true : Integer(ARGV.shift)
  when "--no-trie"        then options[:use_trie] = false
  when "--cache"          then options[:use_cache] = true
  when "--no-cache"       then options[:use_cache] = false
  when "--strict-order"   then options[:strict_order] = true
  when "-n", "--nesting"  then nesting = Integer(ARGV.shift)
  when "-r", "--routes"   then route_count = ARGV.shift.split(",").map { Integer(it) }.sort
  when "-m", "--matches"  then match_count = Integer(ARGV.shift)
  when "-p", "--type"     then options[:type] = ARGV.shift.to_sym
  else
    warn <<~USAGE
      Unknown option: #{ARGV.first}

      Available options:
        --trie [THRESHOLD]    whether to use a trie for matching, or the threshold for using a trie
        --no-trie             do not use a trie for matching
        --cache               enable caching of matches not yet garbage collected
        --no-cache            disable caching of matches not yet garbage collected
        -n, --nesting N       nesting level of patterns, default depends on count
        -r, --routes N1,N2..  number of routes to add
        -m, --matches N       number of matches to perform
    USAGE
    exit 1
  end
end

case options[:type]
when :sinatra, :rails, :cake, :express then prefix = ":"
when :flask                            then prefix, suffix = "<", ">"
when :pyramid, :template               then prefix, suffix = "{", "}"
else
  warn "Unknown type: #{options[:type]}"
  exit 1
end

line_length = 53 + route_count.last.to_s.size

data = route_count.map do |count|
  routes   = []
  examples = []
  _nesting = nesting || count.to_s(17).size
  base     = "a" * _nesting

  count.times do
    segments    = base.split("", _nesting).reverse
    placeholder = String.new("`")
    routes   << segments.map { "/#{it}/#{prefix}#{placeholder.succ!}#{suffix}" }.join
    examples << segments.map { "/#{it}/#{placeholder.succ!}" }.join
    base.succ!
  end

  { count:, routes:, examples:, nesting: _nesting, rand: match_count.times.map { rand(count) } }
end

puts "", " Compilation ".center(line_length, '=')
Benchmark.benchmark do |x|
  data.each do |d|
    x.report("#{d[:count]} routes") do
      set = Mustermann::Set.new(**options)
      d[:routes].each_with_index do |route, index|
        set.add(route, index)
      end
      d[:set] = set
    end
  end
end

puts "", " Matching ".center(line_length, '=')
Benchmark.bmbm do |x|
  data.each do |d|
    set = d[:set]
    x.report("#{d[:count]} routes") do
      d[:rand].each do |index|
        example = d[:examples][index]
        next if match = set.match(example) and match.value == index
        route = d[:routes][index]
        p nil, route, example, match, Mustermann.new(route, ignore_unknown_options: true, **options).match(example), set
        raise "Expected %p but got %p for %p" % [index, match&.value, example]
      end
    end
  end
end
