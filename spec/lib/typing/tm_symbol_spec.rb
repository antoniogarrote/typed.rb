require_relative '../../spec_helper'

describe TypedRb::Model::TmSymbol do

  let(:language) { TypedRb::Language.new }

  context 'with a ruby symbol' do

    it 'parsed the symbol type correctly' do
      result = language.check(':test')
      expect(result).to eq(tysymbol)
    end
  end
end
