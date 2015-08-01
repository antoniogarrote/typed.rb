require_relative '../../spec_helper'

describe TypedRb::Model::TmArrayLiteral do
  it 'parses return instructions with single types' do
    code = <<__CODE
        ts '#fret1 / -> Integer'
        def fret1
          return 1
        end

        fret1
__CODE

    parsed = TypedRb::Language.new.check(code)
    expect(parsed.ruby_type).to eq(Integer)
  end

  it 'parses return instructions with multiple compatible types' do
    code = <<__CODE
        ts '#fret2 / -> Array[Integer]'
        def fret2
          return 1, 2
        end

        fret2
__CODE

    parsed = TypedRb::Language.new.check(code)
    expect(parsed.ruby_type).to eq(Array)
    expect(parsed.type_vars.first.bound.ruby_type).to eq(Integer)
  end

  it 'parses return instructions with multiple incompatible types' do
    code = <<__CODE
        ts '#fret3 / -> Array[Object]'
        def fret3
          return 1, 'string'
        end

        fret3
__CODE

    parsed = TypedRb::Language.new.check(code)
    expect(parsed.ruby_type).to eq(Array)
    expect(parsed.type_vars.first.bound.ruby_type).to eq(Object)
  end
end
