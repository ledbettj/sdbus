require 'spec_helper'

describe Sdbus::TypeParser do
  subject(:parse) { described_class.new.method(:parse_and_transform) }

  it 'parses simple types correctly' do
    parsed = parse.('s')
    type   = parsed.first

    expect(parsed.length).to  eq(1)
    expect(type[:type]).to    eq(:simple)
    expect(type[:ident]).to   eq('s')
  end

  it 'parses array types correctly' do
    parsed = parse.('ai')
    type   = parsed.first

    expect(parsed.length).to   eq(1)
    expect(type[:type]).to     eq(:array)
    expect(type[:contains]).to eq('i')
    expect(type[:ident]).to    eq('ai')
    expect(type[:value]).to    eq(type: :simple, ident: 'i')
  end

  it 'parses dict types correctly' do
    parsed = parse.('a{sb}')
    type   = parsed.first

    expect(parsed.length).to   eq(1)
    expect(type[:type]).to     eq(:dict)
    expect(type[:contains]).to eq('sb')
    expect(type[:ident]).to    eq('a{sb}')
    expect(type[:key]).to      eq(type: :simple, ident: 's')
    expect(type[:value]).to    eq(type: :simple, ident: 'b')
  end

  it 'parses struct types correctly' do
    parsed = parse.('(siib)')
    type   = parsed.first

    expect(parsed.length).to        eq(1)
    expect(type[:values].length).to eq(4)

    expect(type[:type]).to     eq(:struct)
    expect(type[:contains]).to eq('siib')
    expect(type[:ident]).to    eq('(siib)')

    expect(type[:values].first).to eq(type: :simple, ident: 's')
    expect(type[:values].last).to  eq(type: :simple, ident: 'b')
  end

  it 'parses multiple types correctly' do
    parsed = parse.('saia{bb}a(iii)')

    expect(parsed.length).to eq(4)
    expect(parsed.map{ |p| p[:type] }).to eq([:simple, :array, :dict, :array])
  end

end
