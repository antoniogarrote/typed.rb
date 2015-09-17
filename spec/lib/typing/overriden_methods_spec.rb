require_relative '../../spec_helper'

describe TypedRb::Model::TmSend do
  let(:language) { TypedRb::Language.new }

  context 'with a function with multiple type signatures' do
    it 'type checks methods with multiple type signatures' do
      eval('class TOM1; def f(a, *args, &b); end; end')

      base =  <<__CODE
      class TOM1
        ts '#f / String -> Integer'
        ts '#f / String -> Integer -> String'
      end

__CODE

      expr1 = "#{base}TOM1.new.f('a')"
      result = language.check(expr1)
      expect(result).to eq(tyinteger)

      expr2 = "#{base}TOM1.new.f('a', 2)"
      result = language.check(expr2)
      expect(result).to eq(tystring)

      expr3 = "#{base}TOM1.new.f('a', 2, nil)"
      result = language.check(expr3)
      expect(result).to eq(tydynamic)
    end
  end
end
