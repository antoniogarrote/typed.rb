require_relative '../../spec_helper'

describe TypedRb::Types::TyEither do
  describe 'normal' do
    it 'holds a type for the normal execution flow' do
      either = described_class.new
      ty_string = TypedRb::Types::TyString.new
      either[:normal] = ty_string

      expect(either.return?).to eq(false)
      expect(either.break?).to eq(false)
      expect(either.next?).to eq(false)
      expect(either[:normal]).to eq(ty_string)
      expect(either.has_jump?).to eq(false)
    end
  end

  describe 'return' do
    it 'holds a type for the return stack jump flow' do
      either = described_class.new
      ty_string = TypedRb::Types::TyString.new
      ty_return = TypedRb::Types::TyStackJump.return(ty_string)
      either[:return] = ty_return
      expect(either.return?).to eq(true)
      expect(either.break?).to eq(false)
      expect(either.next?).to eq(false)
      expect(either[:return]).to eq(ty_return)
      expect(either.has_jump?).to eq(true)
    end
  end

  describe 'break' do
    it 'holds a type for the break stack jump flow' do
      either = described_class.new
      ty_string = TypedRb::Types::TyString.new
      ty_break = TypedRb::Types::TyStackJump.break(ty_string)
      either[:break] = ty_break
      expect(either.return?).to eq(false)
      expect(either.break?).to eq(true)
      expect(either.next?).to eq(false)
      expect(either[:break]).to eq(ty_break)
      expect(either.has_jump?).to eq(true)
    end
  end

  describe 'next' do
    it 'holds a type for the next stack jump flow' do
      either = described_class.new
      ty_string = TypedRb::Types::TyString.new
      ty_next = TypedRb::Types::TyStackJump.next(ty_string)
      either[:next] = ty_next
      expect(either.return?).to eq(false)
      expect(either.break?).to eq(false)
      expect(either.next?).to eq(true)
      expect(either[:next]).to eq(ty_next)
      expect(either.has_jump?).to eq(true)
    end
  end

  describe '#[]' do
    it 'raises an exception for an invalid type' do
      either = described_class.new

      expect {
        either[:foo]# = TypedRb::Types::TyString.new
      }.to raise_exception(Exception)
    end
  end

  describe '#[]=' do
    it 'raises an exception for an invalid type' do
      either = described_class.new

      expect {
        either[:foo] = TypedRb::Types::TyString.new
      }.to raise_exception(Exception)
    end
  end

  describe '#compatible?' do
    it 'delegates compatiblity check to the normal flow type' do
      either = described_class.new
      either[:normal] = TypedRb::Types::TyString.new

      string_type = TypedRb::Types::TyString.new

      expect(either.compatible?(string_type, :lt)).to eq(true)
      expect {
        float_type = TypedRb::Types::TyObject.new(Float)
        either.compatible?(float_type, :lt)
      }.to raise_exception(TypedRb::Types::UncomparableTypes)
    end
  end

  describe '#compatible_either?' do
    context 'with missing either values' do
      it 'add the missing either values to the current type' do
        either_a = described_class.new
        either_b = described_class.new
        ty_string = TypedRb::Types::TyString.new
        either_a[:return] = TypedRb::Types::TyStackJump.return(ty_string)
        either_b[:break] = TypedRb::Types::TyStackJump.break(ty_string)

        either_a.compatible_either?(either_b)
        expect(either_a[:return].return?).to eq(true)
        expect(either_a[:break].break?).to eq(true)
      end
    end

    context 'with matching either values' do

      it 'computes the max type of normal types' do
        either_a = described_class.new
        either_b = described_class.new
        ty_string = TypedRb::Types::TyString.new
        either_a[:return] = TypedRb::Types::TyStackJump.return(ty_string)
        either_b[:return] = TypedRb::Types::TyStackJump.return(ty_string)

        expect {
          either_a.compatible_either?(either_b)
        }.to_not raise_exception

        ty_float = TypedRb::Types::TyObject.new(Float)
        either_b[:return] = TypedRb::Types::TyStackJump.return(ty_float)
        either_a.compatible_either?(either_b)

        expect(either_a[:return].wrapped_type.ruby_type).to eq(Object)
      end

      it 'adds constraints to type variables matching regular types'do
        either_a = described_class.new
        either_b = described_class.new
        ty_string = TypedRb::Types::TyString.new
        either_a[:return] = TypedRb::Types::TyStackJump.return(ty_string)

        type_var = TypedRb::Types::TypingContext.local_type_variable
        either_b[:return] = TypedRb::Types::TyStackJump.return(type_var)

        before_constraints = TypedRb::Types::TypingContext.all_constraints.count
        expect {
          either_a.compatible_either?(either_b)
        }.to_not raise_exception

        after_constraints = TypedRb::Types::TypingContext.all_constraints.count
        expect(after_constraints).to eq(before_constraints + 1)
        expect(either_a[:return].wrapped_type.class).to eq(TypedRb::Types::Polymorphism::TypeVariable)
      end

      it 'adds constraints to type variables matching regular type_variables'do
        either_a = described_class.new
        either_b = described_class.new

        type_var_a = TypedRb::Types::TypingContext.local_type_variable
        either_a[:return] = TypedRb::Types::TyStackJump.return(type_var_a)

        type_var_b = TypedRb::Types::TypingContext.local_type_variable
        either_b[:return] = TypedRb::Types::TyStackJump.return(type_var_b)

        before_constraints = TypedRb::Types::TypingContext.all_constraints.count
        expect {
          either_a.compatible_either?(either_b)
        }.to_not raise_exception

        after_constraints = TypedRb::Types::TypingContext.all_constraints.count
        expect(after_constraints).to eq(before_constraints + 2)
        expect(either_a[:return].wrapped_type.class).to eq(TypedRb::Types::Polymorphism::TypeVariable)
      end

      it 'type checks correctly types matching dynamic types' do
        either_a = described_class.new
        either_b = described_class.new

        ty_string = TypedRb::Types::TyString.new
        either_a[:return] = TypedRb::Types::TyStackJump.return(ty_string)

        ty_dynamic = TypedRb::Types::TyDynamic.new(String)
        either_b[:return] = TypedRb::Types::TyStackJump.return(ty_dynamic)

        expect {
          either_a.compatible_either?(either_b)
        }.to_not raise_exception

        expect(either_a[:return].wrapped_type.ruby_type).to eq(String)

        # Reverse

        either_a = described_class.new
        either_b = described_class.new

        ty_string = TypedRb::Types::TyString.new
        either_a[:return] = TypedRb::Types::TyStackJump.return(ty_string)

        ty_dynamic = TypedRb::Types::TyDynamic.new(String)
        either_b[:return] = TypedRb::Types::TyStackJump.return(ty_dynamic)

        expect {
          either_b.compatible_either?(either_a)
        }.to_not raise_exception

        expect(either_b[:return].wrapped_type.ruby_type).to eq(String)
      end

      it 'type checks correctly types matching dynamic types' do
        either_a = described_class.new
        either_b = described_class.new

        ty_string = TypedRb::Types::TyString.new
        either_a[:return] = TypedRb::Types::TyStackJump.return(ty_string)

        ty_unit = TypedRb::Types::TyUnit.new
        either_b[:return] = TypedRb::Types::TyStackJump.return(ty_unit)

        expect {
          either_a.compatible_either?(either_b)
        }.to_not raise_exception

        expect(either_a[:return].wrapped_type.ruby_type).to eq(String)

        # Reverse

        either_a = described_class.new
        either_b = described_class.new

        ty_string = TypedRb::Types::TyString.new
        either_b[:return] = TypedRb::Types::TyStackJump.return(ty_string)

        ty_unit = TypedRb::Types::TyUnit.new
        either_a[:return] = TypedRb::Types::TyStackJump.return(ty_unit)

        expect {
          either_a.compatible_either?(either_b)
        }.to_not raise_exception

        expect(either_a[:return].wrapped_type.ruby_type).to eq(String)
      end
    end
  end
end
