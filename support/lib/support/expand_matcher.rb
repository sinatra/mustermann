RSpec::Matchers.define :expand do |values = {}|
  match do |pattern|
    @string  ||= nil
    begin
      expanded = pattern.expand(values)
    rescue Exception
      false
    else
      @string ? @string == expanded : !!expanded
    end
  end

  chain :to do |string|
    @string = string
  end

  failure_message do |pattern|
    message = "expected %p to be expandable with %p" % [pattern, values]
    expanded = pattern.expand(values)
    message << " and result in %p, but got %p" % [@string, expanded] if @string
    message
  end

  failure_message_when_negated do |pattern|
    "expected %p not to be expandable with %p" % [pattern, values]
  end
end