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

  it 'type checks array Pair arg, positive case' do
    code = <<__CODE
      ts '#mlhstestpair1 / Pair[String][Integer] -> Integer'
      def mlhstestpair1((a,b)); b; end
__CODE

    expect {
      language.check(code)
    }.to_not raise_error
  end

  it 'type checks array Pair arg, negative case' do
    code = <<__CODE
      ts '#mlhstestpair1 / Pair[String][Integer] -> Integer'
      def mlhstestpair1((a,b,c)); a; end
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

  it 'type checks pair args for blocks, positive case' do
    code = <<__CODE
      ts '#mlhstestpair3 / Pair[String][Integer] -> &(Pair[String][Integer] -> Integer) -> Integer'
      def mlhstestpair3(p)
        yield p
      end

      mlhstestpair3(cast(['a',1],'Pair[String][Integer]')) { |(a,b)| b }
__CODE

    result = language.check(code)
    expect(result.ruby_type).to eq(Integer)
  end

  it 'type checks pair args for blocks, negative case' do
    code = <<__CODE
      ts '#mlhstestpair3 / Pair[String][Integer] -> &(Pair[String][Integer] -> Integer) -> Integer'
      def mlhstestpair3(p)
        yield p
      end

      mlhstestpair3(cast(['a',1],'Pair[String][Integer]')) { |(a,b)| a }
__CODE
    expect {
    language.check(code)
    }.to raise_error(TypedRb::Types::UncomparableTypes)
  end

  it 'type checks assignation of pairs, positive case' do
    code = <<__CODE
    ts '#x / Pair[String][Integer] -> String'
    def x(p)
      a,b = p
      a
    end
__CODE
    expect {
      language.check(code)
    }.to_not raise_error
  end

  it 'type checks assignation of pairs, negative case' do
    code = <<__CODE
    ts '#x / Pair[String][Integer] -> String'
    def x(p)
      a,b = p
      b
    end
__CODE
    expect {
      language.check(code)
    }.to raise_error(TypedRb::Types::UncomparableTypes)
  end
end
