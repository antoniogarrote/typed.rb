require_relative '../../spec_helper'

describe TypedRb::Model::TmHashLiteral do

  it 'parses hash literals with the same type' do
    code = '{:a => 1, :b => 2}'

    parsed = TypedRb::Language.new.check(code)
    expect(parsed.ruby_type).to eq(Hash)
    expect(parsed.type_vars.first.bound.ruby_type).to eq(Symbol)
    expect(parsed.type_vars.last.bound.ruby_type).to eq(Integer)
  end

  it 'parses hash literals with compatible types' do
    code = '{2 => 1, 3 => Numeric.new, Numeric.new => 4}'

    parsed = TypedRb::Language.new.check(code)
    expect(parsed.ruby_type).to eq(Hash)
    expect(parsed.type_vars.first.bound.ruby_type).to eq(Numeric)
    expect(parsed.type_vars.last.bound.ruby_type).to eq(Numeric)
  end

  it 'parses array literals with nil values' do
    code = '{:x => 1, nil => Numeric.new, :z => nil}'

    parsed = TypedRb::Language.new.check(code)
    expect(parsed.ruby_type).to eq(Hash)
    expect(parsed.type_vars.first.bound.ruby_type).to eq(Symbol)
    expect(parsed.type_vars.last.bound.ruby_type).to eq(Numeric)
  end

  it 'parses array literals with incompatible values' do
    code = '{:x => 1, 2 => "string"}'

    parsed = TypedRb::Language.new.check(code)
    expect(parsed.ruby_type).to eq(Hash)
    expect(parsed.type_vars.first.bound.ruby_type).to eq(Object)
    expect(parsed.type_vars.last.bound.ruby_type).to eq(Object)
  end
end
