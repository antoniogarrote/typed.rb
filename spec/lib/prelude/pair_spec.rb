require_relative '../../spec_helper'
require_relative '../../../lib/typed/prelude'

describe Pair do
  let(:language) { TypedRb::Language.new }

  describe '#instance_variable_defined' do
    it 'type checks / Showable -> Boolean' do
      result = language.check('Pair.of(1,"foo").second')
      expect(result.ruby_type).to eq(String)

      result = language.check('Pair.of(1,"foo").first')
      expect(result.ruby_type).to eq(Integer)
    end
  end
end