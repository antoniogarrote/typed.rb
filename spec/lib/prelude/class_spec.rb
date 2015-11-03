require_relative '../../spec_helper'

describe Class do
  let(:language) { TypedRb::Language.new }

  describe '#initialize' do
    it 'type checks / Class -> Class' do
      result = language.check('Class.new(Object)')
      expect(result.ruby_type).to eq(Class)
    end
  end
end
