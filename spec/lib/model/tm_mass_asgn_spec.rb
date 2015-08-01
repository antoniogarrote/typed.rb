require_relative '../../spec_helper'

describe TypedRb::Model::TmMassAsgn do

  it 'parses mass assignment' do
    code = <<__CODE
       ts '#fma1 / -> Array[Integer]'
       def fma1; Array.(Integer).new; end

       a,b = fma1
__CODE

    parsed = TypedRb::Language.new.check(code)
    expect(parsed.ruby_type).to eq(Array)

    code = <<__CODE
       ts '#fma1 / -> Array[Integer]'
       def fma1; Array.(Integer).new; end

       a,b = fma1
       a
__CODE

    parsed = TypedRb::Language.new.check(code)
    expect(parsed.bound.ruby_type).to eq(Integer)


    code = <<__CODE
       ts '#fma1 / -> Array[Integer]'
       def fma1; Array.(Integer).new; end

       a,b = fma1
       b
__CODE

    parsed = TypedRb::Language.new.check(code)
    expect(parsed.bound.ruby_type).to eq(Integer)

    code = <<__CODE
       ts '#fma1 / -> Array[Integer]'
       def fma1; Array.(Integer).new; end

       ts '#fmai1 / -> Integer'
       def fmai1
         a,b = fma1
         a
       end

      fmai1
__CODE
    parsed = TypedRb::Language.new.check(code)
    expect(parsed.ruby_type).to eq(Integer)
  end

it 'parses mass assignment when returning scalar types' do
    code = <<__CODE
       ts '#fma2 / -> String'
       def fma2; 'string'; end

       a,b = fma2
__CODE

    parsed = TypedRb::Language.new.check(code)
    expect(parsed.ruby_type).to eq(String)

    code = <<__CODE
       ts '#fma2 / -> String'
       def fma2; 'string'; end

       a,b = fma2
       a
__CODE

    parsed = TypedRb::Language.new.check(code)
    expect(parsed.ruby_type).to eq(String)


    code = <<__CODE
       ts '#fma2 / -> String'
       def fma2; 'string'; end

       a,b = fma2
       b
__CODE

    parsed = TypedRb::Language.new.check(code)
    expect(parsed).to eq(tyunit)

    code = <<__CODE
       ts '#fma2 / -> String'
       def fma2; 'string'; end

       ts '#fmai2 / -> String'
       def fmai2
         a,b = fma2
         a
       end

      fmai2
__CODE
    parsed = TypedRb::Language.new.check(code)
    expect(parsed.ruby_type).to eq(String)
  end
end
