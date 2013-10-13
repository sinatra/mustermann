require 'support'
require 'mustermann/to_pattern'

describe Mustermann::ToPattern do
  context String do
    example { "".to_pattern               .should be_a(Mustermann::Sinatra) }
    example { "".to_pattern(type: :rails) .should be_a(Mustermann::Rails)   }
  end

  context Regexp do
    example { //.to_pattern               .should be_a(Mustermann::Regular) }
    example { //.to_pattern(type: :rails) .should be_a(Mustermann::Regular) }
  end

  context Mustermann::Pattern do
    subject(:pattern) { Mustermann.new('') }
    example { pattern.to_pattern.should be == pattern }
    example { pattern.to_pattern(type: :rails).should be_a(Mustermann::Sinatra) }
  end
end
