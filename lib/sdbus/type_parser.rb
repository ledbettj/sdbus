#require 'parslet'

module Sdbus
  class TypeParser
    def parse_and_transform(text)
      parse(text.chars)
    end

    private

    def parse(chars)
      results = []

      while chars.any?
        chars.shift and break if chars.first == ')'
        results.push(parse_one(chars))
      end
      results
    end

    def parse_one(chars)
      case (ch = chars.shift)
      when *%w{y b n q i u x t d h s o g}
        { type: :simple, ident: ch }
      when '('
        children = parse(chars)
        contains = children.map{ |c| c[:ident] }.join('')
        { type: :struct, values: children, contains: contains, ident: "(#{contains})" }
      when 'a'
        if chars.first == '{'
          chars.shift # opening brace
          key   = parse_one(chars)
          value = parse_one(chars)
          chars.shift # closing brace
          contains = "#{key[:ident]}#{value[:ident]}"
          { type: :dict, key: key, value: value, contains: contains, ident: "a{#{contains}}"}
        else
          child = parse_one(chars)
          contains = child[:ident]
          { type: :array, value: child, contains: contains, ident: "a#{contains}" }
        end
      when 'v'
        { type: :variant, ident: 'v' }
      end
    end
  end
end
