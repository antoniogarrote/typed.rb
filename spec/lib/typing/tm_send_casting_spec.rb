require_relative '../../spec_helper'

describe TypedRb::Model::TmSend do
  let(:language) { TypedRb::Language.new }

  it 'casts any value to the provided type' do
    expr = 'cast(\'string\', Integer)'

    result = language.check(expr)
    expect(result).to eq(tyinteger)
  end

  it 'casts values when provided as strings' do
    expr = 'cast(\'string\', \'Integer\')'

    result = language.check(expr)
    expect(result).to eq(tyinteger)
  end

  it 'casts values when provided as a generic type' do
    expr = 'cast(\'string\', \'Array[Integer]\')'

    result = language.check(expr)
    expect(result.to_s).to eq('Array[Class[Integer]]')
  end
end
