RSpec::Matchers.define :match do |expected|
  match do |actual|
    @captures ||= false
    match = actual.match(expected)
    match &&= @captures.all? { |k, v| match[k] == v } if @captures
    match
  end

  chain :capturing do |captures|
    @captures = captures
  end

  failure_message_for_should do |actual|
    require 'pp'
    match = actual.match(expected)
    if match
      key, value = @captures.detect { |k, v| match[k] != v }
      "expected %p to capture %p as %p when matching %p, but got %p\n\nRegular Expression:\n%p" % [
        actual.to_s, key, value, expected, match[key], actual.regexp
      ]
    else
      "expected %p to match %p" % [ actual, expected ]
    end
  end

  failure_message_for_should_not do |actual|
    "expected %p not to match %p" % [
      actual.to_s, expected
    ]
  end
end