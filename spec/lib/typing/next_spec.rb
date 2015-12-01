require_relative '../../spec_helper'

describe ':next term' do
  let(:language) { TypedRb::Language.new }

  it 'is type checked correctly, positive case' do
    code = <<__END
     [1,2,3,4].map { |i| next(i * 2) }
__END

    result = language.check(code)
    expect(result.to_s).to eq('Array[Integer]')
  end

  it 'is type checked correctly, negative case' do
    code = <<__END
     ts '#test_break / Integer -> &(Integer -> Integer) -> Integer'
     def test_break(x)
       yield(x)
     end

     test_break(0) { |x| next("") }
__END

    expect {
      language.check(code)
    }.to raise_error(TypedRb::Types::UncomparableTypes)
  end
end
