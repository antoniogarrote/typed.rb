require_relative '../../spec_helper'

describe TypedRb::Model::TmMlhs do
  let(:language) { TypedRb::Language.new }

  it 'type checks array args, positive case' do
    code = <<__CODE
      ts '#mlhsaddition / Integer -> Integer -> Integer'
      def mlhsaddition(a,b); a + b; end

      ts '#mlhstest1 / Array[Integer] -> Integer'
      def mlhstest1((a,b))
        mlhsaddition(a,b)
      end

      mlhstest1([1,2])
__CODE

    result = language.check(code)
    expect(result.ruby_type).to eq(Integer)
  end

  it 'type checks array args, negative case' do
    code = <<__CODE
      ts '#mlhsaddition2 / String -> Integer'
      def mlhsaddition2(a); 0; end

      ts '#mlhstest2 / Array[Integer] -> Integer'
      def mlhstest2((a,b))
        mlhsaddition2(a)
      end

      mlhstest2([1,2])
__CODE

    expect {
      language.check(code)
    }.to raise_error(TypedRb::Types::UncomparableTypes)
  end

  it 'raises an error if the type of the argument is not an array or tuple' do
    code = <<__CODE
      ts '#mlhstest_error / Integer -> Integer'
      def mlhstest_error((a,b))
        a + b
      end
__CODE

    expect {
      language.check(code)
    }.to raise_error(TypedRb::TypeCheckError)
  end

  it 'type checks array args for blocks, positive case' do
    code = <<__CODE
      ts '#mlhsaddition3 / Integer -> Integer -> Integer'
      def mlhsaddition3(a,b); a + b; end

      ts '#mlhstest3 / Array[Integer] -> &(Array[Integer] -> Integer) -> Integer'
      def mlhstest3(a)
        yield a
      end

      mlhstest3([1,2]) { |(a,b)| mlhsaddition3(a,b) }
__CODE

    result = language.check(code)
    expect(result.ruby_type).to eq(Integer)
  end

  it 'type checks array args for blocks, negative case' do
    code = <<__CODE
      ts '#mlhsaddition4 / Integer -> Integer -> Integer'
      def mlhsaddition4(a,b); a + b; end

      ts '#mlhstest4 / Array[String] -> &(Array[String] -> String) -> Integer'
      def mlhstest4(a)
        yield a
      end

      mlhstest4(['a','b']) { |(a,b)| mlhsaddition4(a,b) }
__CODE

    expect {
      language.check(code)
    }.to raise_error(TypedRb::Types::UncomparableTypes)
  end
end
