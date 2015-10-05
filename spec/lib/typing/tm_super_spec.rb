require_relative '../../spec_helper'

describe TypedRb::Model::TmSuper do
  let(:language) { TypedRb::Language.new }

  it 'type checks invocations of the super keyword' do
    expr = <<__CODE
      class TSA
        ts '#t / Integer -> Integer'
        def t(x); x; end
      end

      class TSB < TSA
       ts '#t / Integer -> Integer'
       def t(x); super; end
      end

      TSB.new.t(1)
__CODE

    result = language.check(expr)
    expect(result.ruby_type).to eq(Integer)
  end

  it 'type checks invocations of the super keyword and arguments' do
    expr = <<__CODE
      class TSA
        ts '#t / Integer -> Integer -> Integer'
        def t(x,y); x+y; end
      end

      class TSB < TSA
       ts '#t / Integer -> Integer'
       def t(x); super(0,x); end
      end

      TSB.new.t(1)
__CODE

    result = language.check(expr)
    expect(result.ruby_type).to eq(Integer)
  end

  it 'type checks invocations of the super keyword and arguments, negative case' do
    expr = <<__CODE
      class TSA
        ts '#t / Integer -> Integer -> Integer'
        def t(x,y); x.to_i+y.to_i; end
      end

      class TSB < TSA
       ts '#t / String -> String'
       def t(x); super(0,x); end
      end

      TSB.new.t('string')
__CODE

    expect {
      language.check(expr)
    }.to raise_error(TypedRb::Types::UncomparableTypes)
  end
end
