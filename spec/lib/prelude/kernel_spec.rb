require_relative '../../spec_helper'

describe Kernel do
  let(:language) { TypedRb::Language.new }

  context '#Array[E]' do
    it 'type checks / Range[E] -> Array[E]' do
      result = language.check('Array(Range.(Integer).new(0, 10))')
      expect(result.ruby_type).to eq(Array)
      expect(result.type_vars.first.bound.ruby_type).to eq(Integer)
    end
  end
end
