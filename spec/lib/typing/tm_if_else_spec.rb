require_relative '../../spec_helper'

describe TypedRb::Model::TmIfElse do
  let(:language) { TypedRb::Language.new }

  it 'types correctly if/then/else branches' do
    expr = <<__CODE
      if true
       1
      else
       2
      end
__CODE

    result = language.check(expr)
    expect(result).to eq(tyinteger)
  end

  it 'types correctly if/then' do
    expr = <<__CODE
     1 if true
__CODE

    result = language.check(expr)
    expect(result).to eq(tyinteger)
  end

  it 'types correctly if/else' do
    expr = <<__CODE
     1 unless true
__CODE
    result = language.check(expr)
    expect(result).to eq(tyinteger)
  end

  it 'types correctly return statements in if/then/else branches' do
    expr = <<__CODE
      ts '#fbite1 / -> Integer'
      def fbite1
        return  1 if true
      end
      fbite1
__CODE

    result = language.check(expr)
    expect(result).to eq(tyinteger)
  end

  it 'types correctly return statements in if/then branches' do
    expr = <<__CODE
      ts '#fbite2 / -> Integer'
      def fbite2
       return 2 unless true
      end
      fbite2
__CODE

    result = language.check(expr)
    expect(result).to eq(tyinteger)
  end

  it 'types correctly return statements in if/else branches' do
    expr = <<__CODE
      ts '#fbite3 / -> Integer'
      def fbite3
        if true
         return  1
        else
         return 2
        end
      end
      fbite3
__CODE

    result = language.check(expr)
    expect(result).to eq(tyinteger)
  end

  it 'types correctly if/then/else statements with errors in the then branch' do
    expr = <<__CODE
     if false
      fail StandardError, 'error'
     else
       1
     end
__CODE

    result = language.check(expr)
    expect(result.ruby_type).to eq(Integer)
  end

  it 'types correctly if/then/else statements with errors in the else branch' do
    expr = <<__CODE
     if true
       1
     else
       fail StandardError, 'error'
     end
__CODE

    result = language.check(expr)
    expect(result.ruby_type).to eq(Integer)
  end
end
