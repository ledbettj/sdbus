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
      rule(variant: simple(:v)) { { type: :variant, ident: 'v'} }
      rule(simple: simple(:s))  { { type: :simple, ident:  s.to_s } }
      rule(struct: subtree(:x)) do
        contains = "#{x.map{ |e| e[:ident] }.join('')}"
        {
          type:     :struct,
          values:   x,
          contains: contains,
          ident:    "(#{contains})"
        }
    end
      rule(array:  subtree(:x)) do
        contains = "#{x[:ident]}"
        {
         type:     :array,
         value:    x,
         contains: contains,
         ident:    "a#{contains}"
        }
      end
      rule(dict: { key: subtree(:k), value: subtree(:v)}) do
        contains = "#{k[:ident]}#{v[:ident]}"
        {
          type:     :dict,
          key:      k,
          value:    v,
          contains: contains,
          ident:    "a{#{contains}}"
        }
      end
    end

    def transformer
      @t ||= Transform.new
    end

    def parse_and_transform(text)
      transformer.apply(parse(text))
    end
  end
end
