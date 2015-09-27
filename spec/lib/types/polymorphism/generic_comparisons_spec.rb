require_relative '../../../spec_helper'

describe TypedRb::Types::Polymorphism::GenericComparisons do
  let(:language) { TypedRb::Language.new }

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
    type_arg = TypedRb::Types::Polymorphism::TypeVariable.new('Array:T:1:?',
                                                              :gen_name => false,
                                                              :upper_bound => int_bound)
    TypedRb::Types::TyGenericSingletonObject.new(Array, [type_arg])
  end

  # Array[? > Numeric]
  let(:array_super_numeric) do
    type_arg = TypedRb::Types::Polymorphism::TypeVariable.new('Array:T:1:?',
                                                              :gen_name => false,
                                                              :lower_bound => numeric_bound)
#    type_arg.bind(numeric_bound)
    TypedRb::Types::TyGenericSingletonObject.new(Array, [type_arg])
  end

  # Array[?]
  let(:arg0) do
    type_arg = TypedRb::Types::Polymorphism::TypeVariable.new('?', :gen_name => false)
    TypedRb::Types::TyGenericSingletonObject.new(Array, [type_arg])
  end

  # Array[Integer]
  let(:arg1) do
    type_arg = TypedRb::Types::Polymorphism::TypeVariable.new('Array:T', :gen_name => false,
                                                              :upper_bound => int_bound,
                                                              :lower_bound => int_bound)
    type_arg.bind(int_bound)
    TypedRb::Types::TyGenericSingletonObject.new(Array, [type_arg])
  end

  # Array[Numeric]
  let(:arg2) do
    type_arg = TypedRb::Types::Polymorphism::TypeVariable.new('Array:T', :gen_name => false,
                                                              :upper_bound => numeric_bound,
                                                              :lower_bound => numeric_bound)
    type_arg.bind(numeric_bound)
    TypedRb::Types::TyGenericSingletonObject.new(Array, [type_arg])
  end

  # Array[? < Numeric]
  let(:arg3) do
    type_arg = TypedRb::Types::Polymorphism::TypeVariable.new('Array:T:1:?',
                                                              :gen_name => false,
                                                              :upper_bound => numeric_bound)
#    type_arg.bind(numeric_bound)
    TypedRb::Types::TyGenericSingletonObject.new(Array, [type_arg])
  end

  # Array[? > Integer]
  let(:arg4) do
    type_arg = TypedRb::Types::Polymorphism::TypeVariable.new('Array:T:1:?',
                                                              :gen_name => false,
                                                              :lower_bound => int_bound)
 #   type_arg.bind(int_bound)
    TypedRb::Types::TyGenericSingletonObject.new(Array, [type_arg])
  end

  # Array[? > Object]
  let(:arg5) do
    type_arg = TypedRb::Types::Polymorphism::TypeVariable.new('Array:T:1:?',
                                                              :gen_name => false,
                                                              :lower_bound => object_bound)
#    type_arg.bind(object_bound)
    TypedRb::Types::TyGenericSingletonObject.new(Array, [type_arg])
  end

  context 'base of :lt comparison is a generic type with an upper_bound' do
    it 'checks correctly: Array<?> :lt Array<? extends Integer> => [?, ?] /< [?, Integer] => FALSE' do
      code = <<__CODE
         ts '#tgcoll2 / Array[? < Integer] -> unit'
         def tgcoll2(gc); end

         arg = Array.('[?]').new

         tgcoll2(arg)
__CODE
      expect {
        language.check(code)
      }.to raise_error(TypedRb::TypeCheckError)
    end

    it 'checks correctly: Array<?> :lt Array<? extends Integer> => [?, ?] /< [?, Integer] => FALSE' do
      expect(arg0.compatible?(array_extends_integer, :lt)).to be_falsey
    end


    it 'checks correctly: Array<? extends Integer> :lt  correctly: Array<?> => [?, Integer] < [?, ?] => TRUE' do
      code = <<__CODE
         ts '#tgcoll3 / Array[?] -> unit'
         def tgcoll3(gc); end

         arg = Array.('[? < Integer]').new

         tgcoll3(arg)
__CODE

      result = language.check(code)
      expect(result.ruby_type).to eq(NilClass)
    end

    it 'checks correctly: Array<? extends Integer> :lt  correctly: Array<?> => [?, Integer] < [?, ?] => TRUE' do
      expect(array_extends_integer.compatible?(arg0, :lt)).to be_truthy
    end


    it 'checks correctly: Array<Integer> :lt Array<? extends Integer> => [Integer, Integer] < [?, Integer] => TRUE' do
      code = <<__CODE
         ts '#tgcoll4 / Array[? < Integer] -> unit'
         def tgcoll4(gc); end

         arg = Array.(Integer).new

         tgcoll4(arg)
__CODE

      result = language.check(code)
      expect(result.ruby_type).to eq(NilClass)
    end

    it 'checks correctly: Array<Integer> :lt Array<? extends Integer> => [Integer, Integer] < [?, Integer] => TRUE' do
      expect(arg1.compatible?(array_extends_integer, :lt)).to be_truthy
    end


    it 'checks correctly: Array<? extends Integer> :lt Array<Integer> => [?, Integer] /< [Integer, Integer] => FALSE' do
      code = <<__CODE
         ts '#tgcoll5 / Array[Integer] -> unit'
         def tgcoll5(gc); end

         arg = Array.('[? < Integer]').new
         tgcoll5(arg)
__CODE
      expect {
        language.check(code)
      }.to raise_error(TypedRb::TypeCheckError)
    end

    it 'checks correctly: Array<? extends Integer> :lt Array<Integer> => [?, Integer] /< [Integer, Integer] => FALSE' do
      expect(array_extends_integer.compatible?(arg1, :lt)).to be_falsey
    end



    it 'checks correctly: Array<Numeric> :lt Array<? extends Integer> => [Numeric, Numeric] /< [?, Integer] => FALSE' do
      code = <<__CODE
         ts '#tgcoll6 / Array[? < Integer] -> unit'
         def tgcoll6(gc); end

         arg = Array.(Numeric).new
         tgcoll6(arg)
__CODE
      expect {
        language.check(code)
      }.to raise_error(TypedRb::TypeCheckError)
    end

    it 'checks correctly: Array<Numeric> :lt Array<? extends Integer> => [Numeric, Numeric] /< [?, Integer] => FALSE' do
      expect(arg2.compatible?(array_extends_integer, :lt)).to be_falsey
    end


    it 'checks correctly: Array<? extends Integer> :lt Array<Numeric> => [?, Integer] /< [Numeric, Numeric] => FALSE' do
      code = <<__CODE
         ts '#tgcoll7 / Array[Numeric] -> unit'
         def tgcoll7(gc); end

         arg = Array.('[? < Integer]').new
         tgcoll7(arg)
__CODE
      expect {
        language.check(code)
      }.to raise_error(TypedRb::TypeCheckError)
    end

    it 'checks correctly: Array<? extends Integer> :lt Array<Numeric> => [?, Integer] /< [Numeric, Numeric] => FALSE' do
      expect(array_extends_integer.compatible?(arg2, :lt)).to be_falsey
    end



    it 'checks correctly: Array<? extends Integer> :lt Array<? extends Integer> => [?, Integer] < [?, Integer] => TRUE' do
      code = <<__CODE
         ts '#tgcoll9 / Array[? < Integer] -> unit'
         def tgcoll9(gc); end

         arg = Array.('[? < Integer]').new

         tgcoll9(arg)
__CODE

      result = language.check(code)
      expect(result.ruby_type).to eq(NilClass)
    end

    it 'checks correctly: Array<? extends Integer> :lt Array<? extends Integer> => [?, Integer] < [?, Integer] => TRUE' do
      expect(array_extends_integer.compatible?(array_extends_integer, :lt)).to be_truthy
    end


    it 'checks correctly: Array<? extends Numeric> :lt Array<? extends Integer> => [?, Numeric] /< [?, Integer] => FALSE' do
      code = <<__CODE
         ts '#tgcoll10 / Array[? < Integer] -> unit'
         def tgcoll10(gc); end

         arg = Array.('[? < Numeric]').new
         tgcoll10(arg)
__CODE
      expect {
        language.check(code)
      }.to raise_error(TypedRb::TypeCheckError)
    end

    it 'checks correctly: Array<? extends Numeric> :lt Array<? extends Integer> => [?, Numeric] /< [?, Integer] => FALSE' do
      expect(arg3.compatible?(array_extends_integer, :lt)).to be_falsey
    end


    it 'checks correctly: Array<? extends Integer> :lt Array<? extends Numeric> => [?, Integer] < [?, Numeric] => TRUE' do
      code = <<__CODE
         ts '#tgcoll11 / Array[? < Numeric] -> unit'
         def tgcoll11(gc); end

         arg = Array.('[? < Integer]').new

         tgcoll11(arg)
__CODE

      result = language.check(code)
      expect(result.ruby_type).to eq(NilClass)
    end

    it 'checks correctly: Array<? extends Integer> :lt Array<? extends Numeric> => [?, Integer] < [?, Numeric] => TRUE' do
      expect(array_extends_integer.compatible?(arg3, :lt)).to be_truthy
    end


    it 'checks correctly: Array<? super Integer> :lt Array<? extends Integer> => [Integer, ?] /< [?, Integer] => FALSE' do
      code = <<__CODE
         ts '#tgcoll12 / Array[? < Integer] -> unit'
         def tgcoll12(gc); end

         arg = Array.('[? > Integer]').new
         tgcoll12(arg)
__CODE
      expect {
        language.check(code)
      }.to raise_error(TypedRb::TypeCheckError)
    end

    it 'checks correctly: Array<? super Integer> :lt Array<? extends Integer> => [Integer, ?] /< [?, Integer] => FALSE' do
      expect(arg4.compatible?(array_extends_integer, :lt)).to be_falsey
    end


    it 'checks correctly: Array<? extends Integer> :lt Array<? super Integer> => [?, Integer] /< [Integer, ?] => FALSE' do
      code = <<__CODE
         ts '#tgcoll13 / Array[? > Integer] -> unit'
         def tgcoll13(gc); end

         arg = Array.('[? < Integer]').new
         tgcoll13(arg)
__CODE
      expect {
        language.check(code)
      }.to raise_error(TypedRb::TypeCheckError)
    end

    it 'checks correctly: Array<? extends Integer> :lt Array<? super Integer> => [?, Integer] /< [Integer, ?] => FALSE' do
      expect(array_extends_integer.compatible?(arg4, :lt)).to be_falsey
    end


    it 'checks correctly: Array<? super Numeric> :lt Array<? extends Integer> => [Numeric, ?] /< [?, Integer] => FALSE' do
      code = <<__CODE
         ts '#tgcoll14 / Array[? < Integer] -> unit'
         def tgcoll14(gc); end

         arg = Array.('[? > Numeric]').new
         tgcoll14(arg)
__CODE
      expect {
        language.check(code)
      }.to raise_error(TypedRb::TypeCheckError)
    end

    it 'checks correctly: Array<? super Numeric> :lt Array<? extends Integer> => [Numeric, ?] /< [?, Integer] => FALSE' do
      expect(array_super_numeric.compatible?(array_extends_integer, :lt)).to be_falsey
    end


    it 'checks correctly: Array<? extends Integer> :lt Array<? super Numeric> => [?, Integer] /< [Numeric, ?] => FALSE' do
      code = <<__CODE
         ts '#tgcoll15 / Array[? > Numeric] -> unit'
         def tgcoll15(gc); end

         arg = Array.('[? < Integer]').new
         tgcoll15(arg)
__CODE
      expect {
        language.check(code)
      }.to raise_error(TypedRb::TypeCheckError)
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

    it 'checks correctly: Array<? super Numeric> :lt Array<? super Integer> => [Numeric, ?] < [Integer, ?] => TRUE' do
      expect(array_super_numeric.compatible?(arg4, :lt)).to be_truthy
    end

    it 'checks correctly: Array<? super Numeric> :lt Array<? super Numeric> => [Numeric, ?] < [Numeric, ?] => TRUE' do
      expect(array_super_numeric.compatible?(array_super_numeric, :lt)).to be_truthy
    end

    it 'checks correctly: Array<? super Object> :lt Array<? super Numeric> => [Object, ?] < [Numeric, ?] => TRUE' do
      expect(arg5.compatible?(array_super_numeric, :lt)).to be_truthy
    end

    it 'checks correctly: Array<? super Numeric> :lt Array<? super Object> => [Numeric, ?] /< [Object, ?] => FALSE' do
      expect(array_super_numeric.compatible?(arg5, :lt)).to be_falsey
    end
  end

  context 'base of :gt comparison is a generic type with an upper_bound' do
    it 'checks correctly: Array<?> :gt Array<? extends Integer> => [?, ?] > [?, Integer] => TRUE' do
      expect(arg0.compatible?(array_extends_integer, :gt)).to be_truthy
    end

    it 'checks correctly: Array<? extends Integer> :gt  correctly: Array<?> => [?, Integer] /> [?, ?] => FALSE' do
      expect(array_extends_integer.compatible?(arg0, :gt)).to be_falsey
    end

    it 'checks correctly: Array<Integer> :gt Array<? extends Integer> => [Integer, Integer] /> [?, Integer] => FALSE' do
      expect(arg1.compatible?(array_extends_integer, :gt)).to be_falsey
    end

    it 'checks correctly: Array<? extends Integer> :gt Array<Integer> => [?, Integer] > [Integer, Integer] => TRUE' do
      expect(array_extends_integer.compatible?(arg1, :gt)).to be_truthy
    end

    it 'checks correctly: Array<Numeric> :gt Array<? extends Integer> => [Numeric, Numeric] /> [?, Integer] => FALSE' do
      expect(arg2.compatible?(array_extends_integer, :gt)).to be_falsey
    end

    it 'checks correctly: Array<? extends Integer> :gt Array<Numeric> => [?, Integer] /> [Numeric, Numeric] => FALSE' do
      expect(array_extends_integer.compatible?(arg2, :gt)).to be_falsey
    end

    it 'checks correctly: Array<? extends Integer> :gt Array<? extends Integer> => [?, Integer] > [?, Integer] => TRUE' do
      expect(array_extends_integer.compatible?(array_extends_integer, :gt)).to be_truthy
    end

    it 'checks correctly: Array<? extends Numeric> :gt Array<? extends Integer> => [?, Numeric] > [?, Integer] => TRUE' do
      expect(arg3.compatible?(array_extends_integer, :gt)).to be_truthy
    end

    it 'checks correctly: Array<? extends Integer> :gt Array<? extends Numeric> => [?, Integer] > [?, Numeric] => FALSE' do
      expect(array_extends_integer.compatible?(arg3, :gt)).to be_falsey
    end

    it 'checks correctly: Array<? super Integer> :gt Array<? extends Integer> => [Integer, ?] /> [?, Integer] => FALSE' do
      expect(arg4.compatible?(array_extends_integer, :gt)).to be_falsey
    end

    it 'checks correctly: Array<? extends Integer> :gt Array<? super Integer> => [?, Integer] /> [Integer, ?] => FALSE' do
      expect(array_extends_integer.compatible?(arg4, :gt)).to be_falsey
    end

    it 'checks correctly: Array<? super Numeric> :gt Array<? extends Integer> => [Numeric, ?] /> [?, Integer] => FALSE' do
      expect(array_super_numeric.compatible?(array_extends_integer, :gt)).to be_falsey
    end

    it 'checks correctly: Array<? extends Integer> :gt Array<? super Numeric> => [?, Integer] /> [Numeric, ?] => FALSE' do
      expect(array_extends_integer.compatible?(array_super_numeric, :gt)).to be_falsey
    end
  end

  context 'base of :gt comparison is a generic type with a lower_bound' do

    it 'checks compatible? Array<?> :gt Array<? super Numeric> => [?, ?] > [Numeric, ?] => TRUE' do
      expect(arg0.compatible?(array_super_numeric, :gt)).to be_truthy
    end

    it 'checks compatible? Array<? super Numeric> :gt Array<?> => [Numeric, ?] /> [?, ?] => FALSE' do
      expect(array_super_numeric.compatible?(arg0, :gt)).to be_falsey
    end

    it 'checks correctly: Array<Integer> :gt Array<? super Numeric> => [Integer, Integer] /> [Numeric, ?] => FALSE' do
      expect(arg1.compatible?(array_super_numeric, :gt)).to be_falsey
    end

    it 'checks correctly: Array<? super Numeric> :gt Array<Integer> =>  [Numeric, ?] /> [Integer, Integer] => FALSE' do
      expect(array_super_numeric.compatible?(arg1, :gt)).to be_falsey
    end

    it 'checks correctly: Array<Numeric> :gt Array<? super Numeric> => [Numeric, Numeric] /> [Numeric, ?] => FALSE' do
      expect(arg2.compatible?(array_super_numeric, :gt)).to be_falsey
    end

    it 'checks correctly: Array<? super Numeric> :gt Array<Numeric> =>  [Numeric, ?] > [Numeric, Numeric] => TRUE' do
      expect(array_super_numeric.compatible?(arg2, :gt)).to be_truthy
    end

    it 'checks correctly: Array<? extends Numeric> :gt Array<? super Numeric> => [?, Numeric] /> [Numeric, ?] => FALSE' do
      expect(arg3.compatible?(array_super_numeric, :gt)).to be_falsey
    end

    it 'checks correctly: Array<? super Numeric> :gt Array<? extends Numeric> => [Numeric,?] /> [?, Numeric] => FALSE' do
      expect(array_super_numeric.compatible?(arg3, :gt)).to be_falsey
    end

    it 'checks correctly: Array<? super Integer> :gt Array<? super Numeric> => [Integer, ?] > [Numeric, ?] => TRUE' do
      expect(arg4.compatible?(array_super_numeric, :gt)).to be_truthy
    end

    it 'checks correctly: Array<? super Numeric> :gt Array<? super Integer> => [Numeric, ?] > [Integer, ?] => FALSE' do
      expect(array_super_numeric.compatible?(arg4, :gt)).to be_falsey
    end

    it 'checks correctly: Array<? super Numeric> :gt Array<? super Numeric> => [Numeric, ?] > [Numeric, ?] => TRUE' do
      expect(array_super_numeric.compatible?(array_super_numeric, :gt)).to be_truthy
    end

    it 'checks correctly: Array<? super Object> :gt Array<? super Numeric> => [Object, ?] /> [Numeric, ?] => FALSE' do
      expect(arg5.compatible?(array_super_numeric, :gt)).to be_falsey
    end

    it 'checks correctly: Array<? super Numeric> :gt Array<? super Object> => [Numeric, ?] > [Object, ?] => TRUE' do
      expect(array_super_numeric.compatible?(arg5, :gt)).to be_truthy
    end
  end
end
