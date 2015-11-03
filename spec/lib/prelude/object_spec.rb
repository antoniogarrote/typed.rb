require_relative '../../spec_helper'

describe Object do
  let(:language) { TypedRb::Language.new }

  describe '#instance_variable_defined' do
    it 'type checks / Showable -> Boolean' do
      result = language.check('Object.new.instance_variable_defined?("@a")')
      expect(result.ruby_type).to eq(TrueClass)

      result = language.check('Object.new.instance_variable_defined?(:@a)')
      expect(result.ruby_type).to eq(TrueClass)
    end
  end

  describe '#instance_of?' do
    it 'type checks / Class -> Boolean' do
      result = language.check('Object.new.instance_of?(Object)')
      expect(result.ruby_type).to eq(TrueClass)
    end
  end
end
