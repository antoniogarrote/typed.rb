require_relative '../spec_helper'

describe TypedRb::Languages::PolyFeatherweightRuby::Types::Polymorphism::Unification do
  it 'should be able to unify a simple constraint' do
    type_var = tyvariable('@a')
    integer = tyobject(Integer)
    type_var.compatible?(integer)

    unification = described_class.new(type_var.constraints)
    unification.run
    expect(type_var.bound).to eq(integer)
  end

  context 'with variable instance assignations' do
    it 'should be able to unify compatible types' do
      type_var = tyvariable('@a')
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
    end

    it 'should find the join of the types' do
      type_var = tyvariable('@a')
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
    end

    it 'should be possible to unify multiple assignations' do
      type_var = tyvariable('@a')
      integer = tyobject(Integer)
      string = tyobject(String)
      type_var2 = tyvariable('@b')
      type_var3 = tyvariable('@c')

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
    end

    it 'should be possible to unify multiple assignations' do
      type_var = tyvariable('@a')
      type_var2 = tyvariable('@b')
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

      # @a = @b = Integer
      # @c = String
      expect(type_var.bound).to eq(numeric)
      expect(type_var2.bound).to eq(numeric)
    end

    it 'should be possible to unify multiple assignations' do
      type_var = tyvariable('@a')
      type_var2 = tyvariable('@b')
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
    end
  end

  context 'with variable instance application' do
    it 'should be able to unify same type' do
      type_var = tyvariable('@a')
      integer = tyobject(Integer)
      # @a = Integer
      type_var.compatible?(integer, :gt)
      # f(a::Integer = @a)
      type_var.compatible?(integer, :lt)

      unification = described_class.new(type_var.constraints)
      unification.run.bindings

      # @a = min(Integer, Integer) if Integer <= Integer
      expect(type_var.bound).to eq(integer)
    end

    it 'should be able to unify matching types' do
      type_var = tyvariable('@a')
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
    end

    it 'should raise a unification exception for incompatible types' do
      type_var = tyvariable('@a')
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
      end.to raise_error TypedRb::Languages::PolyFeatherweightRuby::Types::UncomparableTypes
    end
  end

  context 'with send constraints' do
=begin
    it 'should unify method invocations and detect errors' do
      code = <<__CODE
class ClassV
  ts '#initialize / -> unit'

  ts '#go! / String -> ClassP'
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
  def initialize(cv); end

  ts '#do! / Integer -> Boolean'
  def do!(i); end
end
__CODE

      eval_with_ts(code)
      string = tyobject(String)
      integer = tyobject(Integer)
      classv = tyobject(ClassV)

      # @iv1 = String
      iv1 = tyvariable('@iv1')
      iv1.compatible?(string, :gt)
      # @iv2 = ClassV
      iv2 = tyvariable('@iv2')
      iv2.compatible?(classv, :gt)
      # @iv2 :: go![Integer -> rt1]
      rt1 = tyvariable('rt1')
      iv2.add_constraint(:send,
                         args: [integer],
                         return: rt1,
                         message: :go!)
      # rt1 :: reached?[unit -> rt2]
      rt2 = tyvariable('rt2')
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
      end.to raise_error TypedRb::Languages::PolyFeatherweightRuby::Types::UncomparableTypes
    end
=end
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

      # @iv1 = String
      iv1 = tyvariable('@iv1')
      iv1.compatible?(string, :gt)
      # @iv2 = ClassV
      iv2 = tyvariable('@iv2')
      iv2.compatible?(classv, :gt)
      # @iv2 :: go![Integer -> rt1]
      rt1 = tyvariable('rt1_go!')
      iv2.add_constraint(:send,
                         args: [integer],
                         return: rt1,
                         message: :go!)
      # rt1 :: reached?[unit -> rt2]
      rt2 = tyvariable('rt2_reached?')
      rt1.add_constraint(:send,
                         args: [],
                         return: rt2,
                         message: :reached?)

      # rt2 = return Boolean
      rt2.compatible?(tyboolean, :lt)


      constraints = iv1.constraints + iv2.constraints + rt1.constraints + rt2.constraints
      unification = described_class.new(constraints)
      result = unification.run.bindings
      # TODO add the expectations
      puts result.map(&:to_s)
    end
  end
end
