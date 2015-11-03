require_relative '../../spec_helper'

describe TypedRb::Types::TyGenericSingletonObject do
  let(:language) { TypedRb::Language.new }

  it 'materializes a correctly typed generic type' do

    expr = <<__CODE
      ts 'type GW1[T]'
      class GW1

        ts '#f / -> [T]'
        def f
         2
        end
      end

      GW1.(Integer)
__CODE

    result = language.check(expr)
    expect(result.type_vars.first.lower_bound.ruby_type).to eq(Integer)
    expect(result.type_vars.first.upper_bound.ruby_type).to eq(Integer)
  end

  it 'materializes a correctly typed generic type and subtype' do

    expr = <<__CODE
      ts 'type GW2[T]'
      class GW2

        ts '#f / -> [T]'
        def f
         2
        end
      end

      GW2.(Numeric)
__CODE

    result = language.check(expr)
    expect(result.type_vars.first.lower_bound.ruby_type).to eq(Numeric)
    expect(result.type_vars.first.upper_bound.ruby_type).to eq(Numeric)
  end

  it 'catches inconsistencies in the type application' do

    expr = <<__CODE
      ts 'type GW3[T]'
      class GW3

        ts '#f / -> [T]'
        def f
         2
        end
      end

      GW3.(String)
__CODE

    expect {
      language.check(expr)
    }.to raise_error(TypedRb::Types::Polymorphism::UnificationError)
  end

  context 'with complex bounds in the argument type' do

    it 'parses the type correctly upper bound' do
      expr = <<__CODE
      ts 'type GColl1[T]'
      class GColl1

        ts '#add / [T] -> unit'
        def add(x)
          @val = x
        end

        ts '#pop / -> [T]'
        def pop
          @val
        end
      end

      GColl1.('[? < Numeric]')
__CODE
      result = language.check(expr)
      expect(result.type_vars.first.upper_bound.ruby_type).to eq(Numeric) # -> we can assign -> X = pop() -> X ALWAYS Numeric or greater
      expect(result.type_vars.first.lower_bound).to be_nil # -> we cannot add -> add(X) : X lt NIL -> error
    end

    it 'parses the type correctly with lower bound' do
      expr = <<__CODE
      ts 'type GColl2[T]'
      class GColl2

        ts '#add / [T] -> unit'
        def add(x)
          @val = x
        end

        ts '#pop / -> [T]'
        def pop
          @val
        end
      end

      GColl2.('[? > Numeric]')
__CODE
      result = language.check(expr)
      expect(result.type_vars.first.upper_bound).to be_nil # -> we cannot assign -> X = pop() -> X gt NIL -> error
      expect(result.type_vars.first.lower_bound.ruby_type).to eq(Numeric)  # -> we can add -> add(X) :  X ALWAYS Numeric or smaller
    end

    it 'detects type errors with upper bounds' do
      expr = <<__CODE
      class AG1
         ts '#ag1 / -> unit'
         def ag1;
         end
      end

      class AG2 < AG1
          ts '#ag2 / -> unit'
          def ag2
          end
      end

      class AG3 < AG2; end

      ts 'type GW6[T]'
      class GW6

        ts '#ag2_thing / AG2 -> unit'
        def ag2_thing(ag2); end

        ts '#f / [T] -> [T]'
        def f(x)
          AG2.new
        end
      end

      GW6.('[? < AG3]')
__CODE
      expect {
        language.check(expr)
      }.to raise_error(TypedRb::Types::Polymorphism::UnificationError)
    end

    it 'materializes a correctly typed generic type and subtype with different bounds' do

      expr = <<__CODE
      ts 'type GColl3[T]'
      class GColl3

        ts '#add / [T] -> unit'
        def add(x)
          @val = x
        end

        ts '#pop / -> [T]'
        def pop
          2
        end
      end

      GColl3.('[? < Numeric]')
__CODE

      result = language.check(expr)
      expect(result.type_vars.first.upper_bound.ruby_type).to eq(Numeric) # -> X pop() -> X > Numeric
      expect(result.type_vars.first.lower_bound.ruby_type).to eq(Integer) # -> add(X) -> X < Integer

      expr = <<__CODE
      ts 'type GW8[T]'
      class GW8

        ts '#f / -> [T]'
        def f
         2
        end
      end

      GW8.('[? > Numeric]')
__CODE

      result = language.check(expr)
      expect(result.type_vars.first.upper_bound).to be_nil
      expect(result.type_vars.first.lower_bound.ruby_type).to eq(Numeric)

      expr = <<__CODE
      ts 'type GW9[T]'
      class GW9

        ts '#f / -> [T]'
        def f
         2
        end

        ts '#id / [T] -> [T]'
        def id(x); x; end
      end

      GW9.('[? < Numeric]')
__CODE

      result = language.check(expr)
      expect(result.type_vars.first.upper_bound.ruby_type).to eq(Numeric)
      expect(result.type_vars.first.lower_bound.ruby_type).to eq(Integer)
    end
  end

  context 'mixing generic type definition constraints and instantiation constraints' do

    it 'materializes generic types when passed as arguments' do

      expr = <<__CODE
      ts 'type GColl4[T]'
      class GColl4

        ts '#add / [T] -> unit'
        def add(x)
          @val = x
        end

        ts '#pop / -> [T]'
        def pop
          Numeric.new
        end
      end

      ts '#test_fun / GColl4[? < Integer] -> unit'
      def test_fun(x)
        x.add(1)
      end
__CODE
      expect {
        language.check(expr)
      }.to raise_error(TypedRb::Types::Polymorphism::UnificationError,
                       /Numeric is not a subtype of Integer/)
    end

    it 'materializes generic types when found in arguments sent with a message' do

      expr = <<__CODE
      ts 'type GColl5[T]'
      class GColl5

        ts '#add / [T] -> unit'
        def add(x)
          @val = x
        end

        ts '#pop / -> [T]'
        def pop
          Numeric.new
        end
      end

      ts '#test_fun2 / Object -> unit'
      def test_fun2(x)
        x
      end

      test_fun2(GColl5.('[? < Integer]').new)
__CODE
      expect {
        language.check(expr)
      }.to raise_error(TypedRb::Types::Polymorphism::UnificationError,
                       /Numeric is not a subtype of Integer/)
    end

    it 'supports nested type parameters' do

      expr = <<__CODE
      ts 'type GColl6[T]'
      class GColl6
         ts '#id / [T] -> [T]'
         def id(x); x; end
      end

      GColl6.('Array[Array[Integer]]')
__CODE

      result = language.check(expr)
      expect(result.to_s).to eq('GColl6[Array[Array[Integer]]]')
    end
  end
end
