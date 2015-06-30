describe TypedRb::Languages::PolyFeatherweightRuby::Types::Polymorphism::TypeVariableRegister do
  describe '#initialize' do
    it 'should be possible to create a register without parent' do
      subject = described_class.new
      expect(subject.parent).to be_nil
    end

    it 'should be possible to create a nested register' do
      parent = described_class.new
      child = described_class.new(parent)
      expect(parent.children).to include(child)
      expect(child.parent).to eq(parent)
    end
  end
end
