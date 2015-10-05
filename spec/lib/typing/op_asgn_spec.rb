require_relative '../../spec_helper'

describe 'operator assign operations' do
  let(:language) { TypedRb::Language.new }

  context 'with a local variable' do
    it 'type checks assignment operations over local variables, positive case' do
      expr = <<__CODE
         a = 0
         a += 1
__CODE

      result = language.check(expr)
      expect(result.ruby_type).to eq(Integer)
    end

    it 'type checks assignment operations over local variables, negative case' do
      expr = <<__CODE
         class LocalVarTest
           ts '#+ / LocalVarTest -> LocalVarTest'
           def +(other)
             self
           end
         end

         ts '#x / -> LocalVarTest'
         def x
           a = LocalVarTest.new
           a += 1
         end
__CODE

      expect {
        language.check(expr)
      }.to raise_error(TypedRb::Types::UncomparableTypes)
    end
  end

  context 'with an instance variable' do
    it 'type checks assignment operations over local variables, positive case' do
      expr = <<__CODE
         @a = 0
         @a += 1
__CODE
      result = language.check(expr)
      expect(result.bound.ruby_type).to eq(Integer)
    end

    it 'type checks assignment operations over local variables, negative case' do
      expr = <<__CODE
         class LocalVarTest
           ts '#+ / LocalVarTest -> LocalVarTest'
           def +(other)
             self
           end
         end

         ts '#x / -> LocalVarTest'
         def x
           @a = LocalVarTest.new
           @a += 1
         end
__CODE

      expect {
        language.check(expr)
      }.to raise_error(TypedRb::Types::UncomparableTypes)
    end
  end

  context 'with a global variable' do
    it 'type checks assignment operations over local variables, positive case' do
      expr = <<__CODE
         $TEST_GLOBAL_OPS = 0
         $TEST_GLOBAL_OPS += 1
__CODE
      result = language.check(expr)
      expect(result.bound.ruby_type).to eq(Integer)
    end
  end

  context 'with a constant' do
    it 'type checks assignment operations over local variables, positive case' do
      expr = <<__CODE
         TEST_GLOBAL_OPS = 0
         TEST_GLOBAL_OPS += 1
__CODE
      result = language.check(expr)
      expect(result.ruby_type).to eq(Integer)
    end
  end
end
