require_relative '../../spec_helper'

describe TypedRb::Model::TmWhile do
  let(:language) { TypedRb::Language.new }

  it 'type checks a simple while statement' do
    code = <<__CODE
      while false
        1 - 1
        1 + 1
      end
__CODE

    parsed = language.check(code)
    expect(parsed.ruby_type).to eq(Integer)
  end

  it 'type checks a while statement without body' do
    code = <<__CODE
      while false
      end
__CODE

    parsed = language.check(code)
    expect(parsed.ruby_type).to eq(NilClass)
  end
end
