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
  set_match: 10_000,
  set_size: 1000,
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
  set_match: "Matching #{format[counts[:set_match]]} times against a set of #{format[counts[:set_size]]} patterns",
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

Benchmark.benchmark do |x|
  case ARGV.shift
  when "compile"
    element = String.new("a")
    100.times { Mustermann.new("/#{element.succ!}/:bar") }
    x.report(Mustermann::VERSION) { counts[:compile].times { Mustermann.new("/#{element.succ!}/:bar") } }

  when "single_match"
    pattern = Mustermann.new("/foo/:bar")
    element = String.new("a")
    100.times { pattern.match("/foo/#{element.succ!}") }
    strings = counts[:single_match].times.map { "/foo/#{element.succ!}" }
    x.report(Mustermann::VERSION) { strings.each { |string| pattern === string } }
  
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

    x.report(Mustermann::VERSION) do
      counts[:set_match].times do
        string = routes.sample
        callback.call(string)
      end
    end

  else
    warn "Unknown step: #{ARGV.first}"
    exit 1
  end
end
