require_relative '../../spec_helper'

describe Kernel do
  let(:language) { TypedRb::Language.new }

  context '#Array[E]' do
    it 'type checks / Range[E] -> Array[E]' do
      result = language.check('Array(Range.(Integer).new(0, 10))')
      binding.pry
    end
  end
end
