require_relative '../../spec_helper'

describe TypedRb::Model::TmReturn do

  describe 'Simple for loop' do
    let(:language) { TypedRb::Language.new }

    it 'type checks a for statement, positive case' do
      code = <<__CODE
       ts '#test_i_fn / Integer -> Integer'
       def test_i_fn(x); return 1; end

       test_i_fn(1)
__CODE

      parsed = language.check(code)
      expect(parsed.ruby_type).to eq(Integer)
    end

    it 'type checks a for statement, no return value' do
      code = <<__CODE
       ts '#test_i_fn / Integer -> Integer'
       def test_i_fn(x); return; end

       test_i_fn(1)
__CODE

      parsed = language.check(code)
      expect(parsed.ruby_type).to eq(Integer)
    end

    it 'type checks a for statement, negative case' do
      code = <<__CODE
       ts '#test_i_fn / Integer -> Integer'
       def test_i_fn(x); return '1'; end

       test_i_fn(1)
__CODE

      expect {
        language.check(code)
      }.to raise_error(TypedRb::Types::UncomparableTypes)
    end
  end
end