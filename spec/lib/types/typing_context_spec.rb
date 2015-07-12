require_relative '../../spec_helper'

describe TypedRb::Types::TypingContext do

  describe '.type_variable_for' do
    before do
      described_class.type_variables_register.clear
    end

    it 'should register and find an instance variable for a ruby type' do
      result = described_class.type_variable_for(:instance_variable, '@a', tyobject(Integer).hierarchy)
      expect(result).to be_a(TypedRb::Types::Polymorphism::TypeVariable)
      result2 = described_class.type_variable_for(:instance_variable, '@a', tyobject(Integer).hierarchy)
      expect(result).to eq(result2)
    end

    it 'should find instance variables in the class hierarchy' do
      result = described_class.type_variable_for(:instance_variable, '@a', tyobject(Numeric).hierarchy)
      result2 = described_class.type_variable_for(:instance_variable, '@a', tyobject(Integer).hierarchy)
      expect(result).to eq(result2)
    end

    it 'should not mix instance variables with the same name for different classes' do
      result = described_class.type_variable_for(:instance_variable, '@a', tyobject(Integer).hierarchy)
      result2 = described_class.type_variable_for(:instance_variable, '@a', tyobject(String).hierarchy)
      expect(result).to_not eq(result2)
    end
  end
end
