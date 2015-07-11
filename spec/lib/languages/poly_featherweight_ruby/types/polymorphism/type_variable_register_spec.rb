require_relative '../../spec_helper'

describe TypedRb::Languages::PolyFeatherweightRuby::Types::Polymorphism::TypeVariableRegister do
  describe '#initialize' do
    it 'should be possible to create a register without parent' do
      subject = described_class.new(nil,:top_level)
      expect(subject.parent).to be_nil
    end

    it 'should be possible to create a nested register' do
      parent = described_class.new(nil,:top_level)
      child = described_class.new(parent, :lambda)
      expect(parent.children).to include(child)
      expect(child.parent).to eq(parent)
    end
  end

  describe '#type_variable_for' do
    it 'finds a type variable for a single register' do
      register = described_class.new(nil,:top_level)
      type_variable_one = register.type_variable_for(:instance_variable, '@a', String.ancestors)
      type_variable_two = register.type_variable_for(:instance_variable, '@a', String.ancestors)
      expect(type_variable_one).to eq(type_variable_two)
    end

    it 'finds a type_variable in a nested register' do
      parent = described_class.new(nil,:top_level)
      child = described_class.new(parent, :lambda)
      type_variable_one = parent.type_variable_for(:instance_variable, '@a', String.ancestors)
      type_variable_two = child.type_variable_for(:instance_variable, '@a', String.ancestors)
      expect(type_variable_one).to eq(type_variable_two)
    end

   it 'finds a type variable in the hierarchy' do
     parent = described_class.new(nil,:top_level)
     child = described_class.new(parent, :lambda)
     type_variable_one = parent.type_variable_for(:instance_variable, '@a', Object.ancestors)
     type_variable_two = child.type_variable_for(:instance_variable, '@a', String.ancestors)
     expect(type_variable_one).to eq(type_variable_two)
   end
  end

  describe '#type_variable_for_message' do
    it 'finds a type variable for a single register' do
      register = described_class.new(nil,:top_level)
      type_variable_one = register.type_variable_for_message('x', 'msg')
      type_variable_two = register.type_variable_for_message('x', 'msg')
      expect(type_variable_one).to eq(type_variable_two)
    end

    it 'finds a type_variable in a nested register' do
      parent = described_class.new(nil,:top_level)
      child = described_class.new(parent, :lambda)
      type_variable_one = parent.type_variable_for_message('x', 'msg')
      type_variable_two = child.type_variable_for_message('x', 'msg')
      expect(type_variable_one).to eq(type_variable_two)
    end
  end

  describe '#apply_type' do
    it 'applies a type to a send constraint' do
      TypedRb::Languages::PolyFeatherweightRuby::Types::TypingContext.type_variables_register = described_class.new(nil,:top_level)
      register = TypedRb::Languages::PolyFeatherweightRuby::Types::TypingContext.type_variables_register
      xvar = register.type_variable_for_abstraction(:lambda,'x',top_level_typing_context)
      ret_type = xvar.add_message_constraint('id', [xvar])

      renamed_x = tyvariable('renamed_x')
      renamed_return_id_x = tyvariable('renamed_ret_id_x')
      renamed_register = register.apply_type(nil, {xvar.variable => renamed_x, ret_type.variable => renamed_return_id_x})

      constraints = renamed_register.all_constraints
      expect(constraints.size).to eq(1)
      variable, type, info = constraints.first
      expect(type).to eq :send
      expect(variable).to eq renamed_x
      expect(info[:return]).to eq renamed_return_id_x
      expect(info[:args].size).to eq 1
      expect(info[:args].first).to eq renamed_x

      constraints = register.all_constraints
      expect(constraints.size).to eq(1)
      variable, type, info = constraints.first
      expect(type).to eq :send
      expect(variable).to eq xvar
      expect(info[:return]).to eq ret_type
      expect(info[:args].size).to eq 1
      expect(info[:args].first).to eq xvar
    end

    it 'creates a new register with the right subsitutions in the type_variable' do
      TypedRb::Languages::PolyFeatherweightRuby::Types::TypingContext.type_variables_register = described_class.new(nil,:top_level)
      parent = TypedRb::Languages::PolyFeatherweightRuby::Types::TypingContext.type_variables_register
      ata = parent.type_variable_for(:instance_variable, '@a', String.ancestors)
      argy = parent.type_variable_for_abstraction(:lambda, 'y', top_level_typing_context)

      child = described_class.new(parent, :lambda)
      TypedRb::Languages::PolyFeatherweightRuby::Types::TypingContext.type_variables_register = child

      argx = child.type_variable_for_abstraction(:lambda, 'x', top_level_typing_context)

      argx.compatible?(ata)
      argy.compatible?(argx)

      substitution = tyvariable('substitution')
      result = parent.apply_type(nil, argx.variable => substitution)
      constraints = result.all_constraints
      var, type, info = constraints[0]
      expect(var).to eq(argy)
      expect(type).to eq(:lt)
      expect(info).to eq(substitution)
      var, type, info = constraints[1]
      expect(var).to eq(substitution)
      expect(type).to eq(:lt)
      expect(info).to eq(ata)

      TypedRb::Languages::PolyFeatherweightRuby::Types::TypingContext.type_variables_register = parent
      constraints = TypedRb::Languages::PolyFeatherweightRuby::Types::TypingContext.all_constraints
      var, type, info = constraints[0]
      expect(var).to eq(argy)
      expect(type).to eq(:lt)
      expect(info).to eq(argx)
      var, type, info = constraints[1]
      expect(var).to eq(argx)
      expect(type).to eq(:lt)
      expect(info).to eq(ata)
    end
  end
end
