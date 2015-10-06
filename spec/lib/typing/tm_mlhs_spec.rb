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
end
