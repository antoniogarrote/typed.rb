require_relative '../../spec_helper'

describe ':break term' do
  let(:language) { TypedRb::Language.new }

  it 'is type checked correctly, positive case' do
    code = <<__END
     ts '#test_break / Integer -> &(Integer -> unit) -> Integer'
     def test_break(x)
       yield(x)
     end

     test_break(0) { |x| break(1) }
__END

    result = language.check(code)
    expect(result.to_s).to eq('Integer')
  end

  it 'is type checked correctly, negative case' do
    code = <<__END
     ts '#test_break / Integer -> &(Integer -> unit) -> Integer'
     def test_break(x)
       yield(x)
     end

     test_break(0) { |x| break("") }
__END

    expect {
      language.check(code)
    }.to raise_error(TypedRb::Types::UncomparableTypes)
  end

  context 'with not matching return type' do
    it 'is type checked correctly, positive case' do
      code = <<__END
     ts '#test_break / Integer -> &(Integer -> Integer) -> Integer'
     def test_break(x)
       yield(x)
     end

     test_break(0) { |x| break(1) }
__END

      result = language.check(code)
      expect(result.to_s).to eq('Integer')
    end

    it 'is type checked correctly, negative case' do
      code = <<__END
     ts '#test_break / Integer -> &(String -> Integer) -> Integer'
     def test_break(x)
       yield(x)
     end

     test_break(0) { |x| break(1) }
__END

      expect {
        language.check(code)
      }.to raise_error(TypedRb::Types::UncomparableTypes)
    end
  end
end
