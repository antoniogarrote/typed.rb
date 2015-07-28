require_relative '../../spec_helper'

describe TypedRb::Types::TyGenericObject do
  let(:language) { TypedRb::Language.new }

  it 'instantiates correctly the concrete type from generic type' do

    expr = <<__CODE
        ts '#test_gen_inst_1 / String -> String'
        def test_gen_inst_1(x); x; end

        x = Array.(String).new
        x << 'test'

        test_gen_inst_1(x.at(0))
__CODE

    result = language.check(expr)
    expect(result.ruby_type).to eq(String)

    expr = <<__CODE
        ts '#test_gen_inst_2 / String -> String'
        def test_gen_inst_2(x); x; end

        x = Array.(Integer).new
        x << 1

        test_gen_inst_2(x.at(0))
__CODE

    expect {
      language.check(expr)
    }.to raise_error(TypedRb::Types::UncomparableTypes,
                     'Cannot compare types Class[Integer] <=> String')
  end

  it 'detects errors for the instantiated concrete type' do

    expr = <<__CODE
        x = Array.(Integer).new
        x << 'string'
__CODE

    expect {
      language.check(expr)
    }.to raise_error(TypedRb::Types::UncomparableTypes,'Cannot compare types String <=> Class[Integer]')
  end

  it 'correctly types nested generic types' do
    expr = <<__CODE
       x = Array.('Array[Integer]').new
       x << Array.(Integer).new
       y = x.at(0)
       y << 1
       y.at(0)
__CODE

    result = language.check(expr)
    expect(result.ruby_type).to eq(Integer)
  end

  it 'detects errors in the types of nested generic types' do

    expr = <<__CODE
       x = Array.('Array[Integer]').new
       x << Array.(String).new
       y = x.at(0)
       y << 1
       y.at(0)
__CODE

    expect {
      language.check(expr)
    }.to raise_error(TypedRb::Types::UncomparableTypes,'Cannot compare types Class[Integer] <=> Class[String]')

  end
end
