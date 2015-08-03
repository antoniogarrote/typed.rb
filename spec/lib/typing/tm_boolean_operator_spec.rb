require_relative '../../spec_helper'

describe TypedRb::Model::TmBooleanOperator do
  let(:language) { TypedRb::Language.new }

  it 'type checks boolean operations of the same type' do
    expr = 'true && false'

    result = language.check(expr)
    expect(result.ruby_type).to eq(TrueClass)

    expr = 'true || false'

    result = language.check(expr)
    expect(result.ruby_type).to eq(TrueClass)

    expr = 'true or false'

    result = language.check(expr)
    expect(result.ruby_type).to eq(TrueClass)

    expr = 'true and false'

    result = language.check(expr)
    expect(result.ruby_type).to eq(TrueClass)
  end

  it 'type checks boolean operations with different types' do
    expr = '1 && 0'

    result = language.check(expr)
    expect(result.ruby_type).to eq(Integer)

    expr = '1 || Numeric.new'

    result = language.check(expr)
    expect(result.ruby_type).to eq(Numeric)

    expr = '"string" or Numeric.new'

    result = language.check(expr)
    expect(result.ruby_type).to eq(Object)
  end


  it 'type checks boolean operations with nil values' do
    expr = '1 && nil'

    result = language.check(expr)
    expect(result.ruby_type).to eq(Integer)

    expr = 'nil || Numeric.new'

    result = language.check(expr)
    expect(result.ruby_type).to eq(Numeric)

    expr = '"string" or nil'

    result = language.check(expr)
    expect(result.ruby_type).to eq(String)
  end

  it 'type checks operations with type variables' do

    code = <<__CODE
      class TBOp1
        ts '#test / -> Boolean'
        def test
          @b || false
        end

        ts '#b / -> Boolean'
        def b; @b; end
      end

      TBOp1.new.b
__CODE

    result = language.check(code)
    expect(result.ruby_type).to eq(TrueClass)


    code = <<__CODE
      class TBOp2
        ts '#test / -> Boolean'
        def test
          @b || @c
        end

        ts '#b / -> Boolean'
        def b; @b; end
      end

      TBOp2.new.b
__CODE

    result = language.check(code)
    expect(result.ruby_type).to eq(TrueClass)
  end
end
