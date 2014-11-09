RSpec::Matchers.define :generate_template do |template|
  match { |pattern| pattern.to_templates.include? template }

  failure_message do |pattern|
    "expected %p to generate template %p, but only generated %s" % [
      pattern, template, pattern.to_templates.map(&:inspect).join(', ')
    ]
  end

  failure_message_when_negated do |pattern|
    "expected %p not to generate template %p" % [ pattern, template ]
  end
end

RSpec::Matchers.define :generate_templates do |*templates|
  match { |pattern| pattern.to_templates.sort == templates.sort }

  failure_message do |pattern|
    "expected %p to generate templates %p, but generated %p" % [
      pattern, templates.sort, pattern.to_templates.sort
    ]
  end

  failure_message_when_negated do |pattern|
    "expected %p not to generate templates %p" % [ pattern, templates ]
  end
end