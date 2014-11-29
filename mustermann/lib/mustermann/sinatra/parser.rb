module Mustermann
  class Sinatra < AST::Pattern
    # Sinatra syntax definition.
    # @!visibility private
    class Parser < AST::Parser
      on(nil, ??, ?)) { |c| unexpected(c) }

      on(?*)  { |c| scan(/\w+/) ? node(:named_splat, buffer.matched) : node(:splat) }
      on(?:)  { |c| node(:capture) { scan(/\w+/) } }
      on(?\\) { |c| node(:char, expect(/./)) }
      on(?()  { |c| node(:group) { read unless scan(?)) } }
      on(?|)  { |c| node(:or) }

      on ?{ do |char|
        type = scan(?+) ? :named_splat : :capture
        name = expect(/[\w\.]+/)
        type = :splat if type == :named_splat and name == 'splat'
        expect(?})
        node(type, name)
      end

      suffix ?? do |char, element|
        node(:optional, element)
      end
    end

    private_constant :Parser
  end
end