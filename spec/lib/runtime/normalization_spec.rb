require_relative '../../spec_helper'

describe TypedRb::Runtime::Normalization do
  let(:language) { TypedRb::Language.new }
  it 'normalizes generic types with super types annotations' do
    code = <<__END
    ts 'type TestPair[S][T] super Array[Object]'
    class TestPair < Array
      ts '#first / -> [S]'
    end
    TestPair
__END
    result = language.check(code)
    expect(result.ruby_type).to eq(TestPair)
    expect(result.super_type.ruby_type).to eq(Array)
    expect(result.super_type.type_vars.first.bound.ruby_type).to eq(Object)
  end

  it 'raises an exception if the super type is not a super class of the current type' do
    code = <<__END
    ts 'type TestPair2[S][T] super Array[Object]'
    class TestPair2
    end
__END
    expect {
      language.check(code)
    }.to raise_error(StandardError)
  end
end
