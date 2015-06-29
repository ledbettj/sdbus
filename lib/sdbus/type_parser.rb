require 'parslet'

module Sdbus
  class TypeParser < Parslet::Parser
    rule(:variant){ str('v').as(:variant) }
    rule(:simple) { match('[ybnqiuxtdhsog]').as(:simple) }
    rule(:struct) { (str('(') >> (simple | variant).repeat(1) >> str(')')) }
    rule(:dict)   { str('a{') >> type.as(:key) >> type.as(:value) >> str('}') }
    rule(:array)  { (str('a') >> type) }

    rule(:type) { struct.as(:struct) | array.as(:array) | dict.as(:dict) | simple | variant }
    rule(:type_list) { type.repeat(0) }

    root(:type_list)

    class Transform < Parslet::Transform
      rule(variant: simple(:v)) { { type: :variant} }
      rule(simple: simple(:s))  { { type: :simple, ident:  s.to_s } }
      rule(struct: subtree(:x)) { { type: :struct, values: x } }
      rule(array:  subtree(:x)) { { type: :array,  value: x  } }
      rule(dict: { key: subtree(:k), value: subtree(:v)}) { { type: :dict, key: k, value: v } }
    end

    def transformer
      @t ||= Transform.new
    end

    def parse_and_transform(text)
      transformer.apply(parse(text))
    end
  end
end
