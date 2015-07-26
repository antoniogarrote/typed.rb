require_relative '../../spec_helper'

describe TypedRb::Types::TyGenericObject do
  # Array[? < Integer]
  let(:int_bound) do
    TypedRb::Types::TySingletonObject.new(Integer)
  end

  let(:numeric_bound) do
    TypedRb::Types::TySingletonObject.new(Numeric)
  end

  let(:object_bound) do
    TypedRb::Types::TySingletonObject.new(Object)
  end

  # Array[? < Integer]
  let(:array_extends_integer) do
    type_arg = TypedRb::Types::Polymorphism::TypeVariable.new('Array:T_1',
                                                              :gen_name => false,
                                                              :upper_bound => int_bound)
    type_arg.bind(int_bound)
    TypedRb::Types::TyGenericSingletonObject.new(Array, [type_arg])
  end

  # Array[? > Numeric]
  let(:array_super_numeric) do
    type_arg = TypedRb::Types::Polymorphism::TypeVariable.new('Array:T_1',
                                                              :gen_name => false,
                                                              :lower_bound => numeric_bound)
    type_arg.bind(numeric_bound)
    TypedRb::Types::TyGenericSingletonObject.new(Array, [type_arg])
  end

  # Array[?]
  let(:arg0) do
    type_arg = TypedRb::Types::Polymorphism::TypeVariable.new('Array:T_1', :gen_name => false)
    TypedRb::Types::TyGenericSingletonObject.new(Array, [type_arg])
  end

  # Array[Integer]
  let(:arg1) do
    type_arg = TypedRb::Types::Polymorphism::TypeVariable.new('Array:T_1', :gen_name => false,
                                                              :upper_bound => int_bound,
                                                              :lower_bound => int_bound)
    type_arg.bind(int_bound)
    TypedRb::Types::TyGenericSingletonObject.new(Array, [type_arg])
  end

  # Array[Numeric]
  let(:arg2) do
    type_arg = TypedRb::Types::Polymorphism::TypeVariable.new('Array:T_1', :gen_name => false,
                                                              :upper_bound => numeric_bound,
                                                              :lower_bound => numeric_bound)
    type_arg.bind(numeric_bound)
    TypedRb::Types::TyGenericSingletonObject.new(Array, [type_arg])
  end

  # Array[? < Numeric]
  let(:arg3) do
    type_arg = TypedRb::Types::Polymorphism::TypeVariable.new('Array:T_1',
                                                              :gen_name => false,
                                                              :upper_bound => numeric_bound)
    type_arg.bind(numeric_bound)
    TypedRb::Types::TyGenericSingletonObject.new(Array, [type_arg])
  end

  # Array[? > Integer]
  let(:arg4) do
    type_arg = TypedRb::Types::Polymorphism::TypeVariable.new('Array:T_1',
                                                              :gen_name => false,
                                                              :lower_bound => int_bound)
    type_arg.bind(int_bound)
    TypedRb::Types::TyGenericSingletonObject.new(Array, [type_arg])
  end

  # Array[? > Object]
  let(:arg5) do
    type_arg = TypedRb::Types::Polymorphism::TypeVariable.new('Array:T_1',
                                                              :gen_name => false,
                                                              :lower_bound => object_bound)
    type_arg.bind(object_bound)
    TypedRb::Types::TyGenericSingletonObject.new(Array, [type_arg])
  end

  context 'base of :lt comparison is a generic type with an upper_bound' do
    it 'checks correctly: Array<?> :lt Array<? extends Integer> => [?, ?] /< [?, Integer] => FALSE' do
      expect(arg0.compatible?(array_extends_integer, :lt)).to be_falsey
    end

    it 'checks correctly: Array<? extends Integer> :lt  correctly: Array<?> => [?, Integer] < [?, ?] => TRUE' do
      expect(array_extends_integer.compatible?(arg0, :lt)).to be_truthy
    end

    it 'checks correctly: Array<Integer> :lt Array<? extends Integer> => [Integer, Integer] < [?, Integer] => TRUE' do
      expect(arg1.compatible?(array_extends_integer, :lt)).to be_truthy
    end

    it 'checks correctly: Array<? extends Integer> :lt Array<Integer> => [?, Integer] /< [Integer, Integer] => FALSE' do
      expect(array_extends_integer.compatible?(arg1, :lt)).to be_falsey
    end

    it 'checks correctly: Array<Numeric> :lt Array<? extends Integer> => [Numeric, Numeric] /< [?, Integer] => FALSE' do
      expect(arg2.compatible?(array_extends_integer, :lt)).to be_falsey
    end

    it 'checks correctly: Array<? extends Integer> :lt Array<Numeric> => [?, Integer] /< [Numeric, Numeric] => FALSE' do
      expect(array_extends_integer.compatible?(arg2, :lt)).to be_falsey
    end

    it 'checks correctly: Array<? extends Integer> :lt Array<? extends Integer> => [?, Integer] < [?, Integer] => TRUE' do
      expect(array_extends_integer.compatible?(array_extends_integer, :lt)).to be_truthy
    end

    it 'checks correctly: Array<? extends Numeric> :lt Array<? extends Integer> => [?, Numeric] /< [?, Integer] => FALSE' do
      expect(arg3.compatible?(array_extends_integer, :lt)).to be_falsey
    end

    it 'checks correctly: Array<? extends Integer> :lt Array<? extends Numeric> => [?, Integer] < [?, Numeric] => TRUE' do
      expect(array_extends_integer.compatible?(arg3, :lt)).to be_truthy
    end

    it 'checks correctly: Array<? super Integer> :lt Array<? extends Integer> => [Integer, ?] /< [?, Integer] => FALSE' do
      expect(arg4.compatible?(array_extends_integer, :lt)).to be_falsey
    end

    it 'checks correctly: Array<? extends Integer> :lt Array<? super Integer> => [?, Integer] /< [Integer, ?] => FALSE' do
      expect(array_extends_integer.compatible?(arg4, :lt)).to be_falsey
    end

    it 'checks correctly: Array<? super Numeric> :lt Array<? extends Integer> => [Numeric, ?] /< [?, Integer] => FALSE' do
      expect(array_super_numeric.compatible?(array_extends_integer, :lt)).to be_falsey
    end

    it 'checks correctly: Array<? extends Integer> :lt Array<? super Numeric> => [?, Integer] /< [Numeric, ?] => FALSE' do
      expect(array_extends_integer.compatible?(array_super_numeric, :lt)).to be_falsey
    end
  end

  context 'base of :lt comparison is a generic type with a lower_bound' do

    it 'checks compatible? Array<?> :lt Array<? super Numeric> => [?, ?] /< [Numeric, ?] => FALSE' do
      expect(arg0.compatible?(array_super_numeric, :lt)).to be_falsey
    end

    it 'checks compatible? Array<? super Numeric> :lt Array<?> => [Numeric, ?] /< [?, ?] => TRUE' do
      expect(array_super_numeric.compatible?(arg0, :lt)).to be_truthy
    end

    it 'checks correctly: Array<Integer> :lt Array<? super Numeric> => [Integer, Integer] /< [Numeric, ?] => FALSE' do
      expect(arg1.compatible?(array_super_numeric, :lt)).to be_falsey
    end

    it 'checks correctly: Array<? super Numeric> :lt Array<Integer> =>  [Numeric, ?] /< [Integer, Integer] => FALSE' do
      expect(array_super_numeric.compatible?(arg1, :lt)).to be_falsey
    end

    it 'checks correctly: Array<Numeric> :lt Array<? super Numeric> => [Numeric, Numeric] < [Numeric, ?] => TRUE' do
      expect(arg2.compatible?(array_super_numeric, :lt)).to be_truthy
    end

    it 'checks correctly: Array<? super Numeric> :lt Array<Numeric> =>  [Numeric, ?] < [Numeric, Numeric] => FALSE' do
      expect(array_super_numeric.compatible?(arg2, :lt)).to be_falsey
    end

    it 'checks correctly: Array<? extends Numeric> :lt Array<? super Numeric> => [?, Numeric] /< [Numeric, ?] => FALSE' do
      expect(arg3.compatible?(array_super_numeric, :lt)).to be_falsey
    end

    it 'checks correctly: Array<? super Numeric> :lt Array<? extends Numeric> => [Numeric,?] /< [?, Numeric] => FALSE' do
      expect(array_super_numeric.compatible?(arg3, :lt)).to be_falsey
    end

    it 'checks correctly: Array<? super Integer> :lt Array<? super Numeric> => [Integer, ?] /< [Numeric, ?] => FALSE' do
      expect(arg4.compatible?(array_super_numeric, :lt)).to be_falsey
    end

    it 'checks correctly: Array<? super Numeric> :lt Array<? super Integer> => [Numeric, ?] /< [Integer, ?] => TRUE' do
      expect(array_super_numeric.compatible?(arg4, :lt)).to be_truthy
    end

    it 'checks correctly: Array<? super Numeric> :lt Array<? super Numeric> => [Numeric, ?] < [Numeric, ?] => TRUE' do
      expect(array_super_numeric.compatible?(array_super_numeric, :lt)).to be_truthy
    end

    it 'checks correctly: Array<? super Object> :lt Array<? super Numeric> => [Object, ?] < [Numeric, ?] => TRUE' do
      expect(arg5.compatible?(array_super_numeric, :lt)).to be_truthy
    end

    it 'checks correctly: Array<? super Numeric> :lt Array<? super Object> => [Numeric, ?] < [Object, ?] => FALSE' do
      expect(array_super_numeric.compatible?(arg5, :lt)).to be_falsey
    end
  end
end
