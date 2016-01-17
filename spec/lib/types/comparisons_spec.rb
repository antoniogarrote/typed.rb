require_relative '../../spec_helper'

describe TypedRb::Types::TyObject do
  context 'comparisons' do
    it 'can compare tyobjects correctly' do
      expect(described_class.new(Integer) < described_class.new(Numeric)).to eq(true)
      expect(described_class.new(Integer) <= described_class.new(Numeric)).to eq(true)
      expect(described_class.new(Integer) == described_class.new(Integer)).to eq(true)
      expect(described_class.new(Numeric) == described_class.new(Numeric)).to eq(true)
      expect(described_class.new(Integer) != described_class.new(Numeric)).to eq(true)
      expect(described_class.new(Numeric) != described_class.new(Integer)).to eq(true)
      expect(described_class.new(Numeric) > described_class.new(Integer)).to eq(true)
      expect(described_class.new(Numeric) >= described_class.new(Integer)).to eq(true)
    end

    it 'can compare tyobjects non ordered' do
      expect {
        described_class.new(Integer) < described_class.new(String)
      }.to raise_error(ArgumentError)
      expect {
        described_class.new(Integer) <= described_class.new(String)
      }.to raise_error(ArgumentError)

      expect(described_class.new(Integer) != described_class.new(String)).to eq(true)
      expect(described_class.new(String) != described_class.new(Integer)).to eq(true)

      expect {
        described_class.new(Integer) > described_class.new(String)
      }.to raise_error(ArgumentError)
      expect {
        described_class.new(Integer) >= described_class.new(String)
      }.to raise_error(ArgumentError)
    end
  end
end
