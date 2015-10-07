require_relative '../../spec_helper'

describe TypedRb::Model::TmRangeLiteral do

  let(:language) { TypedRb::Language.new }

  it 'parses ranges with the same type' do
    code = '0..10'
    result = language.check(code)
    expect(result.ruby_type).to eq(Range)
    expect(result.type_vars.first.bound.ruby_type).to eq(Integer)

    code = '"a"..."z"'
    result = language.check(code)
    expect(result.ruby_type).to eq(Range)
    expect(result.type_vars.first.bound.ruby_type).to eq(String)
  end

  it 'fails for incompatible types' do
    code = '0..10.0'
    expect {
      language.check(code)
    }.to raise_error
  end
end
