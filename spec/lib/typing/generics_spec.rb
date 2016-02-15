require_relative '../../spec_helper'

describe 'generics use case
when 
  
end' do
  let(:language) { TypedRb::Language.new }

  it 'applies arguments to generic types' do
    code = <<__END
      ts 'type TestGen1[T]'
      class TestGen1
        ts '#gm / [T] -> [T]'
        def gm(t)
          t
        end
      end

      TestGen1.(String).new.gm('string')
__END
    result = language.check(code)
    expect(result.ruby_type).to eq(String)

    code = <<__END
      ts 'type TestGen1[T]'
      class TestGen1
        ts '#gm / [T] -> &([T] -> [T]) -> [T]'
        def gm(t)
          yield t
        end
      end

      TestGen1.(String).new.gm('string') { |t| 'string' }
__END
    result = language.check(code)
    expect(result.ruby_type).to eq(String)

    code = <<__END
      ts 'type TestGen1[T]'
      class TestGen1
        ts '#gm / [T] -> &([T] -> [T]) -> [T]'
        def gm(t)
          yield t
        end
      end

      TestGen1.(String).new.gm('string') { |t| 2 }
__END

    expect do
      language.check(code)
    end.to raise_error(TypedRb::TypeCheckError)
  end


  it 'applies arguments to generic types without implementation' do
    code = <<__END
      xs = Array.(String).new
      xs << 'string'
      xs.at(0)
__END
    result = language.check(code)
    expect(result.ruby_type).to eq(String)

    code = <<__END
      xs = Array.(String).new
      xs << 2
      xs.at(0)
__END

    expect do
      language.check(code)
    end.to raise_error(TypedRb::TypeCheckError)
  end

  it 'materializes generic types using type variables' do
    code = <<__END
       ts 'type TestGen2[T]'
       class TestGen2

         ts '#gm / [T] -> Array[T]'
         def gm(x)
           xs = Array.('[T]').new
           xs << x
           xs
         end
       end

       TestGen2.(String).new.gm('x')
__END

    result = language.check(code)
    expect(result.to_s).to eq('Array[String]')
  end

  it 'detects errors materializing generic types using type variables' do
    code = <<__END
       ts 'type TestGen2[T][U]'
       class TestGen2

         ts '#gm / [T] -> [U] -> Array[T]'
         def gm(x,y)
           xs = Array.('[T]').new
           xs << y
           xs
         end
       end

       TestGen2.(String,Integer).new.gm('x',2)
__END

    expect do
      language.check(code)
    end.to raise_error(TypedRb::TypeCheckError)
  end

  it 'type-checks correctly super type generics' do
    code = <<__END
    class Array
      ts '#last / Integer... -> [T]'
    end

    ts 'type MyContainerG1[T] super Array[Object]'
    class MyContainerG1 < Array
      ts '#first / -> [T]'
    end

    MyContainerG1.(String).new.last
__END

    result = language.check(code)
    expect(result.ruby_type).to eq(Object)
  end

  it 'type-checks correctly super type generics detecting type errors based on the super-type parameter' do
    code = <<__END
    ts 'type BaseGen1[T]'
    class BaseGen1
      ts '#getString / -> String'
      def getString
       'a string'
      end

      ts '#in_subclass / -> [T]'
      def in_subclass
        getString
      end
    end

    ts 'type MyContainerG2[T] super BaseGen1[String]'
    class MyContainerG2 < BaseGen1
    end

    ts 'type MyContainerG3[T] super BaseGen1[Integer]'
    class MyContainerG3 < BaseGen1
    end
__END

    expect do
      language.check(code)
    end.to raise_error(TypedRb::Types::Polymorphism::UnificationError)
  end

  it 'type-checks correctly super type generics detecting type errors based on the super-type parameter on type instantiation' do
    code = <<__END
    ts 'type BaseGen2[T]'
    class BaseGen2
      ts '#getString / -> String'
      def getString
       'a string'
      end

      ts '#in_subclass / -> [T]'
      def in_subclass
        getString
      end
    end

    ts 'type MyContainerG4[T] super BaseGen2[T]'
    class MyContainerG4 < BaseGen2
    end
    BaseGen2.(String).new
    MyContainerG4.(Integer).new
__END

    expect do
      language.check(code)
    end.to raise_error(TypedRb::Types::Polymorphism::UnificationError)
  end

end
