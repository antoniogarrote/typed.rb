require_relative '../../spec_helper'

describe TypedRb::Model::TmSequencing do
  it 'parses sequencing instructions without return type' do
    code = <<__CODE
       1
       2
       'string'
__CODE

    parsed = TypedRb::Language.new.check(code)
    expect(parsed.ruby_type).to eq(String)
  end

  it 'parses sequencing instructions with return type' do
    code = <<__CODE
       ts '#st1 / -> String'
       def st1
        return 'string'
        nil
       end

       st1
__CODE

    parsed = TypedRb::Language.new.check(code)
    expect(parsed.ruby_type).to eq(String)
  end

  it 'parses sequencing instructions with multiple return types' do
    code = <<__CODE
       ts '#st2 / -> Numeric'
       def st2
        return 1
        return Numeric.new
        nil
       end

       st2
__CODE

    parsed = TypedRb::Language.new.check(code)
    expect(parsed.ruby_type).to eq(Numeric)
  end

  it 'parses sequencing instructions with multiple return types and dynamic objects' do
    code = <<__CODE
       ts '#st2 / -> Numeric'
       def st2
        return 1
        return dynamic
        nil
       end

       st2
__CODE

    parsed = TypedRb::Language.new.check(code)
    expect(parsed.ruby_type).to eq(Numeric)
  end

  it 'parses sequencing instructions with nested nodes' do

    code = <<__CODE
       ts '#st3 / -> Boolean'
       def st3
         if true
           1
           true
         else
           'string'
           false
         end
         0
         return true
         nil
       end

       st3
__CODE

    parsed = TypedRb::Language.new.check(code)
    expect(parsed.class).to eq(TypedRb::Types::TyBoolean)

  end
end
