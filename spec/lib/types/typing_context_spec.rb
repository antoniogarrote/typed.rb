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

  describe 'namespaces' do
    eval('module TCNS1; AC=0; module TCNS2; class A; end; class B; BC=1; end; end; end;')

    before do
      described_class.namespace.clear
    end

    it 'works like a stack' do
      expect(described_class.namespace.count).to eq(0)
      described_class.namespace_push('TCNS1')
      described_class.namespace_push('TCNS2')
      described_class.namespace_push('A')

      expect(described_class.namespace).to eq(['TCNS1', 'TCNS2', 'A'])

      described_class.namespace_pop
      described_class.namespace_pop
      described_class.namespace_pop
      expect(described_class.namespace.count).to eq(0)
    end

    it 'handles compound class names' do
      expect(described_class.namespace.count).to eq(0)
      described_class.namespace_push('TCNS1')
      described_class.namespace_push('TCNS2::A')

      expect(described_class.namespace).to eq(['TCNS1', 'TCNS2', 'A'])
    end

    it 'is able to find nested classes' do
      expect(described_class.namespace.count).to eq(0)
      described_class.namespace_push('TCNS1')
      described_class.namespace_push('TCNS2')

      result = described_class.find_namespace('A')
      expect(result).to eq(TCNS1::TCNS2::A)

      result = described_class.find_namespace('AC')
      expect(result).to eq(TCNS1::AC)

      result = described_class.find_namespace('B::BC')
      expect(result).to eq(TCNS1::TCNS2::B::BC)

      result = described_class.find_namespace('TCNS2::B::BC')
      expect(result).to eq(TCNS1::TCNS2::B::BC)

      result = described_class.find_namespace('::String')
      expect(result).to eq(String)

      result = described_class.find_namespace('TCNS1::TCNS2::B::BC')
      expect(result).to eq(TCNS1::TCNS2::B::BC)

      result = described_class.find_namespace('::TCNS1::TCNS2::B::BC')
      expect(result).to eq(TCNS1::TCNS2::B::BC)
    end
  end
end
