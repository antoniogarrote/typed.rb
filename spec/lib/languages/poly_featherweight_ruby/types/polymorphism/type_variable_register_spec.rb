require_relative '../../spec_helper'

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

  describe '#type_variable_for' do
    it 'finds a type variable for a single register' do
      register = described_class.new
      type_variable_one = register.type_variable_for(:instance_variable, '@a', String.ancestors)
      type_variable_two = register.type_variable_for(:instance_variable, '@a', String.ancestors)
      expect(type_variable_one).to eq(type_variable_two)
    end

    it 'finds a type_variable in a nested register' do
      parent = described_class.new
      child = described_class.new(parent)
      type_variable_one = parent.type_variable_for(:instance_variable, '@a', String.ancestors)
      type_variable_two = child.type_variable_for(:instance_variable, '@a', String.ancestors)
      expect(type_variable_one).to eq(type_variable_two)
    end

    it 'finds a type variable in the hierarchy' do
      parent = described_class.new
      child = described_class.new(parent)
      type_variable_one = parent.type_variable_for(:instance_variable, '@a', Object.ancestors)
      type_variable_two = child.type_variable_for(:instance_variable, '@a', String.ancestors)
      expect(type_variable_one).to eq(type_variable_two)
    end
  end

  describe '#type_variable_for_message' do
    it 'finds a type variable for a single register' do
      register = described_class.new
      type_variable_one = register.type_variable_for_message('x', 'msg')
      type_variable_two = register.type_variable_for_message('x', 'msg')
      expect(type_variable_one).to eq(type_variable_two)
    end

    it 'finds a type_variable in a nested register' do
      parent = described_class.new
      child = described_class.new(parent)
      type_variable_one = parent.type_variable_for_message('x', 'msg')
      type_variable_two = child.type_variable_for_message('x', 'msg')
      expect(type_variable_one).to eq(type_variable_two)
    end
  end

  describe '#apply_type' do
    it 'creates a new register with the right subsitutions in the type_variable' do
      TypedRb::Languages::PolyFeatherweightRuby::Types::TypingContext.type_variables_register = described_class.new
      parent = TypedRb::Languages::PolyFeatherweightRuby::Types::TypingContext.type_variables_register
      ata = parent.type_variable_for(:instance_variable, '@a', String.ancestors)
      argy = parent.type_variable_for_abstraction(:lambda, 'y', top_level_typing_context)

      child = described_class.new(parent)
      TypedRb::Languages::PolyFeatherweightRuby::Types::TypingContext.type_variables_register = child

      argx = child.type_variable_for_abstraction(:lambda, 'x', top_level_typing_context)

      argx.compatible?(ata)
      argy.compatible?(argx)

      puts "-- before --"
      parent.all_constraints.each do |constraint|
        puts constraint.inspect
      end
      result = parent.apply_type(nil, argx.variable => tyvariable('substitution'))
      puts "-- after --"
      result.all_constraints.each do |constraint|
        puts constraint.inspect
      end
      puts "-- and --"
      TypedRb::Languages::PolyFeatherweightRuby::Types::TypingContext.type_variables_register = parent
      TypedRb::Languages::PolyFeatherweightRuby::Types::TypingContext.all_constraints.each do |constraint|
        puts constraint.inspect
      end
    end
  end
end
