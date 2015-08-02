require_relative '../../spec_helper'

describe TypedRb::Model::TmModule do

  it 'parses ruby modules' do
    code = <<__CODE
        module TMod1
           ts '#x / -> unit'
           def x; 'test'; end
        end
__CODE

    parsed = TypedRb::Language.new.check(code)
    expect(parsed.is_a?(TypedRb::Types::TyExistentialType)).to eq(true)
    expect(parsed.ruby_type).to eq(TMod1)
  end
end
