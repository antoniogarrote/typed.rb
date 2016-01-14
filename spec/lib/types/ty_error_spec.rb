require_relative '../../spec_helper'

describe TypedRb::Types::TyError do

  describe '#to_s' do
    it 'returns a string representation' do
      expect(described_class.new.to_s).to eq('error')
    end
  end

  describe '#compatible?' do
    it 'is compatible with any type'do
      expect(described_class.new.compatible?(nil)).to eq(true)
      expect(described_class.new.compatible?(described_class.new)).to eq(true)
      expect(described_class.new.compatible?(TypedRb::Types::TyObject.new(Object))).to eq(true)
    end
  end
end