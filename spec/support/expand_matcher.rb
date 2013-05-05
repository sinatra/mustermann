RSpec::Matchers.define :expand do |values = {}|
  match do |pattern|
    @string  ||= nil
    begin
      expanded = pattern.expand(values)
    rescue Exception
      false
    else
      @string ? @string == expandend : expandend
    end
  end

  chain :to do |string|
    @string = string
  end

  failure_message_for_should do |pattern|
    message = "expected %p to be expandable with %p" % [pattern, values]
    begin
      expanded = pattern.expand(values)
      message << " and result in %p, but got %p" % [@string, expanded] if @string
    rescue Exception => error
      message << ", but raised %p" % error
    end
    message
  end

  failure_message_for_should_not do |pattern|
    "expected %p not to be expandable with %p" % [pattern, values]
  end
end