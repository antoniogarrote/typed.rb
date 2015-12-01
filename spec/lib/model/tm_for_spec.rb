require_relative '../../spec_helper'

describe TypedRb::Model::TmFor do

  describe 'Simple for loop' do
    let(:language) { TypedRb::Language.new }

    it 'type checks a for statement, positive case' do
      code = <<__CODE
       ts '#test_i_fn / Integer -> Integer'
       def test_i_fn(x); x + 1; end

       for i in 0..3
         test_i_fn(i)
       end
__CODE

      parsed = language.check(code)
      expect(parsed.ruby_type).to eq(Integer)
    end

    it 'type checks a for statement, negative case' do
      code = <<__CODE
       ts '#test_s_fn / String -> Integer'
       def test_s_fn(x); 0; end

       for i in 0..3
         test_s_fn(i)
       end
__CODE

      expect {
        language.check(code)
      }.to raise_error(TypedRb::Types::UncomparableTypes)
    end
  end

  describe 'Simple for loop, break' do
    let(:language) { TypedRb::Language.new }

    it 'type checks a for statement' do
      code = <<__CODE
       ts '#test_i_fn / Integer -> Integer'
       def test_i_fn(x); x + 1; end

       for i in 0..3
         break 7
         ""
       end
__CODE

      parsed = language.check(code)
      expect(parsed.ruby_type).to eq(Integer)
    end
  end

  describe 'Simple for loop, break' do
    let(:language) { TypedRb::Language.new }

    it 'type checks a for statement' do
      code = <<__CODE
       a = for i in 0..3
             next(3)
             nil
           end
       a
__CODE

      parsed = language.check(code)
      expect(parsed.ruby_type).to eq(Integer)
    end
  end
end
