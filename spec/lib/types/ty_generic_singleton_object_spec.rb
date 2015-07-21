require_relative '../../spec_helper'

describe TypedRb::Types::TyGenericSingletonObject do
  let(:language) { TypedRb::Language.new }

  it 'is possible to materialize a correctly typed generic type' do

    expr = <<__END
      ts 'type GW1[T]'
      class GW1

        ts '#f / -> [T]'
        def f
         2
        end
      end

      GW1.(Integer)
__END

    result = language.check(expr)
    expect(result.type_vars.first.lower_bound.ruby_type).to eq(Integer)
    expect(result.type_vars.first.upper_bound.ruby_type).to eq(Integer)
  end

  it 'is possible to materialize a correctly typed generic type and subtype' do

    expr = <<__END
      ts 'type GW2[T]'
      class GW2

        ts '#f / -> [T]'
        def f
         2
        end
      end

      GW2.(Numeric)
__END

    result = language.check(expr)
    expect(result.type_vars.first.lower_bound.ruby_type).to eq(Numeric)
    expect(result.type_vars.first.upper_bound.ruby_type).to eq(Numeric)
  end

  it 'catches inconsistencies in the type application' do

    expr = <<__END
      ts 'type GW3[T]'
      class GW3

        ts '#f / -> [T]'
        def f
         2
        end
      end

      GW3.(String)
__END

    expect {
      language.check(expr)
    }.to raise_error(TypedRb::Types::Polymorphism::UnificationError)
  end

  context 'with complex bounds in the argument type' do

    it 'parses the type correctly upper bound' do
      expr = <<__END
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
__END
      result = language.check(expr)
      expect(result.type_vars.first.upper_bound.ruby_type).to eq(Numeric) # -> we can assign -> X = pop() -> X ALWAYS Numeric or greater
      expect(result.type_vars.first.lower_bound).to be_nil # -> we cannot add -> add(X) : X lt NIL -> error
    end

    it 'parses the type correctly with lower bound' do
      expr = <<__END
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
__END
      result = language.check(expr)
      expect(result.type_vars.first.upper_bound).to be_nil # -> we cannot assign -> X = pop() -> X gt NIL -> error
      expect(result.type_vars.first.lower_bound.ruby_type).to eq(Numeric)  # -> we can add -> add(X) :  X ALWAYS Numeric or smaller
    end

    it 'detects type errors with upper bounds' do
      expr = <<__END
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
__END
      expect {
        language.check(expr)
      }.to raise_error(TypedRb::Types::Polymorphism::UnificationError)
    end

    it 'is possible to materialize a correctly typed generic type and subtype with different bounds' do

      expr = <<__END
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
__END

      result = language.check(expr)
      expect(result.type_vars.first.upper_bound.ruby_type).to eq(Numeric) # -> X pop() -> X > Numeric
      expect(result.type_vars.first.lower_bound.ruby_type).to eq(Integer) # -> add(X) -> X < Integer

      expr = <<__END
      ts 'type GW8[T]'
      class GW8

        ts '#f / -> [T]'
        def f
         2
        end
      end

      GW8.('[? > Numeric]')
__END

      result = language.check(expr)
      expect(result.type_vars.first.upper_bound).to be_nil
      expect(result.type_vars.first.lower_bound.ruby_type).to eq(Numeric)

      expr = <<__END
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
__END

      result = language.check(expr)
      expect(result.type_vars.first.upper_bound.ruby_type).to eq(Numeric)
      expect(result.type_vars.first.lower_bound.ruby_type).to eq(Integer)
    end
  end
end
