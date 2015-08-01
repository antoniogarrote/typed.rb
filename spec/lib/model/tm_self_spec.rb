require_relative '../../spec_helper'

describe TypedRb::Model::TmSelf do
  it 'returns the self reference type' do
    code = <<__CODE
      class TSelfRef1
         ts '#test / -> TSelfRef1'
         def test
           self
         end
      end

     TSelfRef1.new.test
__CODE

    parsed = TypedRb::Language.new.check(code)
    expect(parsed.ruby_type).to eq(TSelfRef1)
  end
end
