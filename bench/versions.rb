# frozen_string_literal: true

known_versions = %w[
  3.1.1 3.1.0
  3.0.4 3.0.3 3.0.2 3.0.1 3.0.0
  2.0.2 2.0.1 2.0.0
  1.1.2 1.1.1 1.1.0
]

counts = {
  compile: 1_000,
  single_match: 5_000_000,
  params: 1_000_000,
  set_match: 10_000,
  set_size: 1000,
  look_ahead_fail: 500,
}

format = proc do |count|
  if count >= 1_000_000
    "#{count / 1_000_000}M"
  elsif count >= 1_000
    "#{count / 1_000}K"
  else
    count.to_s
  end
end

scenarios = {
  compile: "Compilation of #{format[counts[:compile]]} patterns",
  single_match: "Matching #{format[counts[:single_match]]} times against a single pattern",
  simple_params: "Extracting params #{format[counts[:params]]} times for a simple pattern",
  complex_params: "Extracting params #{format[counts[:params]]} times for a complex pattern",
  set_match: "Matching #{format[counts[:set_match]]} times against a set of #{format[counts[:set_size]]} patterns",
  look_ahead_fail: "Matching #{format[counts[:look_ahead_fail]]} times with look-ahead pattern on a long failing input (atomic group speedup)",
}

case version = ENV['MUSTERMANN_VERSION']
when /^\d+\./
  begin
    gem "mustermann", version
  rescue Gem::LoadError
    Gem.install "mustermann", version
    gem "mustermann", version
  end
when "bundler"
  require "bundler/setup"
when String
  $LOAD_PATH.unshift File.expand_path(version)
else
  scenarios.each do |step, title|
    next unless ARGV.empty? or ARGV.include?(step.to_s)
    puts "", title, "", "       user       system     total    real"
    ["bundler", *known_versions].each do |version|
      env = { "MUSTERMANN_VERSION" => version }
      if version != "bundler"
        ENV.each_key do |key|
          next unless key.start_with?("BUNDLE")
          env[key] = nil
        end
        env["RUBYOPT"] = nil
      end
      system(env, "ruby", "-W0", __FILE__, step.to_s )
    end
  end
  return
end

require "benchmark"
require "mustermann"
require "mustermann/version"

version = Mustermann::VERSION[/^(\d+\.\d+\.\d+)/]

Benchmark.benchmark do |x|
  case ARGV.shift
  when "compile"
    element = String.new("a")
    100.times { Mustermann.new("/#{element.succ!}/:bar") }
    x.report(version) { counts[:compile].times { Mustermann.new("/#{element.succ!}/:bar") } }

  when "single_match"
    pattern = Mustermann.new("/foo/:bar")
    element = String.new("a")
    100.times { pattern.match("/foo/#{element.succ!}") }
    strings = counts[:single_match].times.map { "/foo/#{element.succ!}" }
    x.report(version) { strings.each { |string| pattern === string } }
  
  when "simple_params"
    pattern = Mustermann.new("/:controller/:action")
    element = String.new("a")
    100.times { pattern.params("/#{element.succ!}/show.html") }
    strings = counts[:params].times.map { "/#{element.succ!}/show.html" }
    x.report(version) { strings.each { |string| pattern.params(string) } }
  
  when "complex_params"
    pattern = Mustermann.new("/:controller/:action(.:format)")
    element = String.new("a")
    100.times { pattern.params("/#{element.succ!}/show.html") }
    strings = counts[:params].times.map { "/#{element.succ!}/show.html" }
    x.report(version) { strings.each { |string| pattern.params(string) } }

  when "set_match"
    patterns = []
    routes   = []
    element  = String.new("aa")
    counts[:set_size].times do
      patterns << Mustermann.new("/#{element.succ!}/:bar")
      routes << "/#{element}/#{element}"
    end

    begin
      require "mustermann/set"
      set = Mustermann::Set.new(patterns)
      callback = proc { |s| set.match(s) }
    rescue LoadError => e
      raise e unless e.path == "mustermann/set"
      callback = proc { |s| patterns.select { |p| p === s } }
    end

    x.report(version) do
      counts[:set_match].times do
        string = routes.sample
        callback.call(string)
      end
    end

  when "look_ahead_fail"
    # /:a:b? triggers the look-ahead transformer: :a and :b share the same
    # character class ([^\/\?#]) with no separator between them.  Current
    # Mustermann wraps the head capture (:a) in an atomic group so Oniguruma
    # does not re-examine characters it has already committed to.  Older
    # versions emit a plain non-atomic capture, which backtracks O(n) times
    # when the overall match fails.
    #
    # The failing string ends with "/trailing" — the extra segment cannot be
    # consumed by either capture (both exclude '/'), so the engine must try
    # every possible split of the 5 000-character prefix before giving up.
    # On current Mustermann this takes ~0.11 s; on older versions ~0.57 s.
    pattern = Mustermann.new("/:a:b?")
    failing  = "/" + "x" * 5_000 + "/trailing"
    10.times { pattern.match(failing) }
    x.report(version) { counts[:look_ahead_fail].times { pattern.match(failing) } }

  else
    warn "Unknown step: #{ARGV.first}"
    exit 1
  end
end
