require_relative '../../spec_helper'

describe TypedRb::Types::Polymorphism::Unification do
  it 'should be able to unify a simple constraint' do
    type_var = TypedRb::Types::TypingContext.type_variable_for(:test, '@varx', [Object])
    integer = tyobject(Integer)
    type_var.compatible?(integer, :lt)

    unification = described_class.new(type_var.constraints)
    unification.run
    expect(type_var.bound).to eq(integer)
    expect(type_var.upper_bound).to eq(integer)
    expect(type_var.lower_bound).to be_nil
  end

  context 'with variable instance assignations' do
    it 'should be able to unify compatible types' do
      type_var = TypedRb::Types::TypingContext.type_variable_for(:test, '@b', [Object])
      integer = tyobject(Integer)
      numeric = tyobject(Numeric)
      # @a = Integer
      type_var.compatible?(integer, :gt)
      # @a = Numeric
      type_var.compatible?(numeric, :gt)

      unification = described_class.new(type_var.constraints)
      unification.run.bindings

      # @a = max(Integer, Numeric)
      expect(type_var.bound).to eq(numeric)
      expect(type_var.lower_bound).to eq(numeric)
      expect(type_var.upper_bound).to be_nil
    end

    it 'should find the join of the types' do
      type_var = TypedRb::Types::TypingContext.type_variable_for(:test, '@c', [Object])
      integer = tyobject(Integer)
      string = tyobject(String)
      # @a = Integer
      type_var.compatible?(integer, :gt)
      # @a = String
      type_var.compatible?(string, :gt)

      unification = described_class.new(type_var.constraints)
      unification.run.bindings

      # @a = max(Integer, String) => join(Integer, Sring) => Object[Comparable,Kernel]
      expect(type_var.bound.with_ruby_type).to be_falsey
      expect(type_var.bound.ruby_type).to eq(Object)
      expect(type_var.bound.modules).to include(Comparable)
      expect(type_var.bound.modules).to include(Kernel)
      expect(type_var.lower_bound.with_ruby_type).to be_falsey
      expect(type_var.lower_bound.ruby_type).to eq(Object)
      expect(type_var.lower_bound.modules).to include(Comparable)
      expect(type_var.lower_bound.modules).to include(Kernel)
      expect(type_var.upper_bound).to be_nil
    end

    it 'should be possible to unify multiple assignations' do
      type_var = TypedRb::Types::TypingContext.type_variable_for(:test, '@d', [Object])
      integer = tyobject(Integer)
      string = tyobject(String)
      type_var2 = TypedRb::Types::TypingContext.type_variable_for(:test, '@e', [Object])
      type_var3 = TypedRb::Types::TypingContext.type_variable_for(:test, '@f', [Object])

      # @a = Integer
      type_var.compatible?(integer, :gt)
      # @b = @a
      type_var2.compatible?(type_var, :gt)
      # @c = String
      type_var3.compatible?(string, :gt)

      unification = described_class.new(type_var.constraints + type_var2.constraints + type_var3.constraints)
      unification.run.bindings

      # @a = @b = Integer
      # @c = String
      expect(type_var.bound).to eq(integer)
      expect(type_var2.bound).to eq(integer)
      expect(type_var3.bound).to eq(string)
      expect(type_var.lower_bound).to eq(integer)
      expect(type_var2.lower_bound).to eq(integer)
      expect(type_var3.lower_bound).to eq(string)
      expect(type_var.upper_bound).to be_nil
      expect(type_var2.upper_bound).to be_nil
      expect(type_var3.upper_bound).to be_nil
    end

    it 'should be possible to unify multiple assignations' do
      type_var = TypedRb::Types::TypingContext.type_variable_for(:test, '@g', [Object])
      type_var2 = TypedRb::Types::TypingContext.type_variable_for(:test, '@h', [Object])
      integer = tyobject(Integer)
      numeric = tyobject(Numeric)


      # @a = Numeric
      type_var.compatible?(numeric, :gt)
      # @b = @a
      type_var2.compatible?(type_var, :gt)
      # @b = Integer
      type_var2.compatible?(integer, :gt)

      unification = described_class.new(type_var.constraints + type_var2.constraints)
      unification.run.bindings

      # @a = @b = Numeric
      expect(type_var.bound).to eq(numeric)
      expect(type_var2.bound).to eq(numeric)
      expect(type_var.lower_bound).to eq(numeric)
      expect(type_var2.lower_bound).to eq(numeric)
      expect(type_var.upper_bound).to be_nil
      expect(type_var2.upper_bound).to be_nil
    end

    it 'should be possible to unify multiple assignations' do
      type_var = TypedRb::Types::TypingContext.type_variable_for(:test, '@i', [Object])
      type_var2 = TypedRb::Types::TypingContext.type_variable_for(:test, '@j', [Object])
      integer = tyobject(Integer)
      numeric = tyobject(Numeric)


      # @a = Integer
      type_var.compatible?(integer, :gt)
      # @b = @a
      type_var2.compatible?(type_var, :gt)
      # @b = Numeric
      type_var2.compatible?(numeric, :gt)

      unification = described_class.new(type_var.constraints + type_var2.constraints)
      unification.run.bindings

      # @a = @b = Numeric
      expect(type_var.bound).to eq(numeric)
      expect(type_var2.bound).to eq(numeric)
      expect(type_var.lower_bound).to eq(numeric)
      expect(type_var2.lower_bound).to eq(numeric)
      expect(type_var.upper_bound).to be_nil
      expect(type_var2.upper_bound).to be_nil
    end
  end

  context 'with variable instance application' do
    it 'should be able to unify same type' do
      type_var = TypedRb::Types::TypingContext.type_variable_for(:test, '@k', [Object])
      integer = tyobject(Integer)
      # @a = Integer
      type_var.compatible?(integer, :gt)
      # f(a::Integer = @a)
      type_var.compatible?(integer, :lt)

      unification = described_class.new(type_var.constraints)
      unification.run.bindings

      # @a = min(Integer, Integer) if Integer <= Integer
      expect(type_var.bound).to eq(integer)
      expect(type_var.lower_bound).to eq(integer)
      expect(type_var.upper_bound).to eq(integer)
    end

    it 'should be able to unify matching types' do
      type_var = TypedRb::Types::TypingContext.type_variable_for(:test, '@l', [Object])
      integer = tyobject(Integer)
      numeric = tyobject(Numeric)
      # @a = Integer
      type_var.compatible?(integer, :gt)
      # f(a::Numeric = @a)
      type_var.compatible?(numeric, :lt)

      unification = described_class.new(type_var.constraints)
      unification.run.bindings

      # @a = min(Integer, Numeric) if Integer <= Numeric
      expect(type_var.bound).to eq(integer)
      expect(type_var.lower_bound).to eq(integer)
      expect(type_var.upper_bound).to eq(numeric)
    end

    it 'should raise a unification exception for incompatible types' do
      type_var = TypedRb::Types::TypingContext.type_variable_for(:test, '@m', [Object])
      string = tyobject(String)
      numeric = tyobject(Numeric)
      # @a = String
      type_var.compatible?(string, :gt)
      # f(a::Numeric = @a)
      type_var.compatible?(numeric, :lt)

      unification = described_class.new(type_var.constraints)
      expect do
        # @a = min(String, Numeric) if String < Numeric => FAIL
        unification.run.bindings
      end.to raise_error TypedRb::Types::UncomparableTypes
    end
  end

  context 'with send constraints' do

    it 'should unify method invocations and detect errors' do
      code = <<__CODE
class ClassV1
  ts '#initialize / -> unit'

  ts '#go! / String -> ClassP1'
  def go!(s); end
end

class ClassP1
  ts '#initialize / String -> unit'
  def initialize(s); end

  ts '#reached? / -> Boolean'
  def reached?; end
end

class A1
  ts '#initialize / ClassV1 -> unit'
  def initialize(cv); end

  ts '#do! / Integer -> Boolean'
  def do!(i); end
end
__CODE

      eval_with_ts(code)
      string = tyobject(String)
      integer = tyobject(Integer)
      classv = tyobject(ClassV1)

      # @iv1 = String
      iv1 = TypedRb::Types::TypingContext.type_variable_for(:test, '@iv1', [Object])
      iv1.compatible?(string, :gt)
      # @iv2 = ClassV
      iv2 = TypedRb::Types::TypingContext.type_variable_for(:test, '@iv2', [Object])
      iv2.compatible?(classv, :gt)
      # @iv2 :: go![Integer -> rt1]
      rt1 = TypedRb::Types::TypingContext.type_variable_for(:test, 'rt1', [Object])
      iv2.add_constraint(:send,
                         args: [integer],
                         return: rt1,
                         message: :go!)
      # rt1 :: reached?[unit -> rt2]
      rt2 = TypedRb::Types::TypingContext.type_variable_for(:test, 'rt2', [Object])
      rt1.add_constraint(:send,
                         args: [],
                         return: rt2,
                         message: :reached!)

      # rt2 = return Boolean
      rt2.compatible?(tyboolean, :lt)


      constraints = iv1.constraints + iv2.constraints + rt1.constraints + rt2.constraints
      unification = described_class.new(constraints)
      expect do
        # iv2 => ClassV, E? ClassV::go! [Integer -> ?] => ERROR
        unification.run.bindings
      end.to raise_error TypedRb::Types::UncomparableTypes
    end

    it 'should unify method invocations and accept valid inputs' do
      code = <<__CODE
class ClassV
  ts '#initialize / -> unit'

  ts '#go! / Integer -> ClassP'
  def go!(s); end
end

class ClassP
  ts '#initialize / String -> unit'
  def initialize(s); end

  ts '#reached? / -> Boolean'
  def reached?; end
end

class A
  ts '#initialize / ClassV -> unit'
  def initialize(cv)
   # @a = cv
  end

  ts '#do! / Integer -> Boolean'
  def do!(i)
   # @a.go!(n).reached?
  end
end
__CODE

      eval_with_ts(code)
      string = tyobject(String)
      integer = tyobject(Integer)
      classv = tyobject(ClassV)
      classp = tyobject(ClassP)

      # @iv1 = String
      iv1 = TypedRb::Types::TypingContext.type_variable_for(:test, '@iv1b', [Object])
      iv1.compatible?(string, :gt)
      # @iv2 = ClassV
      iv2 = TypedRb::Types::TypingContext.type_variable_for(:test, '@iv2b', [Object])
      iv2.compatible?(classv, :gt)
      # @iv2 :: go![Integer -> rt1]
      rt1 = TypedRb::Types::TypingContext.type_variable_for(:test, 'rt1_go!', [Object])
      iv2.add_constraint(:send,
                         args: [integer],
                         return: rt1,
                         message: :go!)
      # rt1 :: reached?[unit -> rt2]
      rt2 = TypedRb::Types::TypingContext.type_variable_for(:test, 'rt2_reached?', [Object])
      rt1.add_constraint(:send,
                         args: [],
                         return: rt2,
                         message: :reached?)

      # rt2 = return Boolean
      rt2.compatible?(tyboolean, :lt)


      constraints = iv1.constraints + iv2.constraints + rt1.constraints + rt2.constraints

      described_class.new(constraints).run.bindings

      expect(iv1.bound).to eq(string)
      expect(iv2.bound).to eq(classv)
      expect(rt1.bound).to eq(classp)
      expect(rt2.bound).to eq(tyboolean)
    end
  end
end
