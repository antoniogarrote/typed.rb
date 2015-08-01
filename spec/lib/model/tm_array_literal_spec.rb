require_relative '../../spec_helper'

describe TypedRb::Model::TmArrayLiteral do

  it 'parses array literals with the same type' do
    code = '[1, 2, 3]'

    parsed = TypedRb::Language.new.check(code)
    expect(parsed.ruby_type).to eq(Array)
    expect(parsed.type_vars.first.bound.ruby_type).to eq(Integer)
  end

  it 'parses array literals with compatible types' do
    code = '[1, Numeric.new, 3]'

    parsed = TypedRb::Language.new.check(code)
    expect(parsed.ruby_type).to eq(Array)
    expect(parsed.type_vars.first.bound.ruby_type).to eq(Numeric)
  end

  it 'parses array literals with nil values' do
    code = '[1, Numeric.new, nil]'

    parsed = TypedRb::Language.new.check(code)
    expect(parsed.ruby_type).to eq(Array)
    expect(parsed.type_vars.first.bound.ruby_type).to eq(Numeric)
  end

  it 'parses array literals with incompatible values' do
    code = '[1, "string"]'

    parsed = TypedRb::Language.new.check(code)
    expect(parsed.ruby_type).to eq(Array)
    expect(parsed.type_vars.first.bound.ruby_type).to eq(Object)
  end
end
